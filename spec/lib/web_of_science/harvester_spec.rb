# frozen_string_literal: true

# require the helper module: http://savonrb.com/version2/testing.html
require 'savon/mock/spec_helper'

describe WebOfScience::Harvester do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  subject(:harvester) { described_class.new }

  before(:all) { savon.mock!   }

  after(:all)  { savon.unmock! }

  let(:author) { create :russ_altman, :blank_orcid } # use a blank orcid, because these mocks work with the name query
  let(:wos_uids) { %w[WOS:A1976BW18000001 WOS:A1972N549400003] } # from wos_retrieve_by_id_response.xml
  let(:author_name_response) { File.read('spec/fixtures/wos_client/wos_harvest_author_name_response.xml') }
  let(:retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response.xml') }
  let(:wos_rec) do
    WebOfScience::Record.new(record: File.read('spec/fixtures/wos_client/wos_record_A1972N549400003.xml'))
  end
  let(:any_records_will_do) do
    WebOfScience::Records.new(encoded_records: File.read('spec/fixtures/wos_client/medline_encoded_records.html'))
  end

  context 'savon' do
    before do
      allow(WebOfScience).to receive(:client).and_return(WebOfScience::Client.new('secret'))
      savon.expects(:authenticate).returns(File.read('spec/fixtures/wos_client/authenticate.xml'))
    end

    shared_examples 'it_can_process_records' do
      it 'creates new WebOfScienceSourceRecord and author.contributions' do
        expect { harvest_process }.to change(WebOfScienceSourceRecord, :count).and change {
                                                                                     author.contributions.count
                                                                                   }
      end
    end

    describe '#harvest' do
      before do
        savon.expects(:search).with(message: :any).returns(author_name_response)
        savon.expects(:retrieve_by_id).with(message: :any).returns(retrieve_by_id_response)
      end

      let(:harvest_process) { harvester.harvest([author]) }

      it_behaves_like 'it_can_process_records'

      it 'logs exceptions for processing an author' do
        expect(author.harvested).to be nil
        processor = WebOfScience::ProcessRecords.new(author, any_records_will_do)
        allow(processor).to receive(:execute).and_raise(RuntimeError)
        allow(WebOfScience::ProcessRecords).to receive(:new).and_return(processor)
        expect(NotificationManager).to receive(:error)
        harvest_process
        expect(author.harvested).to be true
        expect(author.should_harvest?).to be false
      end
    end

    describe '#process_author' do
      let(:harvest_process) { harvester.process_author(author) }

      before do
        savon.expects(:search).with(message: :any).returns(author_name_response)
        savon.expects(:retrieve_by_id).with(message: :any).returns(retrieve_by_id_response)
      end

      it_behaves_like 'it_can_process_records'

      context 'with existing publication and/or contribution data' do
        let(:retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_record_A1976BW18000001_response.xml') }

        before do
          contrib = Contribution.new(
            author_id: author.id, cap_profile_id: author.cap_profile_id,
            featured: false, status: 'new', visibility: 'private'
          )
          Publication.create!(active: true, pub_hash: wos_rec.pub_hash, wos_uid: wos_rec.uid,
                              pubhash_needs_update: true, contributions: [contrib])
        end

        # Use a new record WITHOUT a publication for WOS:A1976BW18000001, from wos_retrieve_by_id_response.xml
        it 'processes records that have no publication' do
          expect(Publication.find_by(wos_uid: 'WOS:A1976BW18000001')).to be_nil
          expect { harvest_process }.to change {
                                          Publication.find_by(wos_uid: 'WOS:A1976BW18000001')
                                        }.from(nil).to(Publication)
        end
      end
    end

    describe '#process_uids' do
      let(:harvest_process) { harvester.process_uids(author, wos_uids) }

      context 'savon' do
        before { savon.expects(:retrieve_by_id).with(message: :any).returns(retrieve_by_id_response) }

        it_behaves_like 'it_can_process_records'
      end
    end
  end

  context 'non savon' do
    context 'when matching Publication is unpaired with author' do
      let(:wos_rec_01) do
        WebOfScience::Record.new(record: File.read('spec/fixtures/wos_client/wos_record_A1976BW18000001.xml'))
      end
      let(:contrib) do
        Contribution.new(
          author_id: author.id, cap_profile_id: author.cap_profile_id,
          featured: false, status: 'new', visibility: 'private'
        )
      end
      let(:pub_1) do
        Publication.new(active: true, pub_hash: wos_rec_01.pub_hash, wos_uid: wos_rec_01.uid,
                        pubhash_needs_update: true)
      end
      let(:pub_2) do
        Publication.new(active: true, pub_hash: wos_rec.pub_hash, wos_uid: wos_rec.uid, pubhash_needs_update: true,
                        contributions: [contrib])
      end

      before do
        pub_1.save!
        pub_2.save!
      end

      describe '#author_contributions' do
        it 'returns WOS-UIDs only for existing publications' do
          expect(harvester.send(:author_contributions, author, wos_uids + ['WOS:123'])).to eq wos_uids
        end

        it 'creates new Contribution' do
          # NOTE: new source record not added when matching pub already found
          expect(author.publications.map(&:wos_uid)).not_to include(wos_uids.first)
          expect { harvester.send(:author_contributions, author, wos_uids) }
            .to change { author.contributions.count }.from(1).to(2)
            .and change { pub_1.contributions.count }.from(0).to(1)
            .and not_change { pub_2.contributions.count }
          expect(author.publications.reload.map(&:wos_uid)).to include(*wos_uids)
        end
      end

      describe '#author_uid' do
        it 'returns Publication' do
          expect(harvester.author_uid(author, wos_uids.first)).to eq pub_1
          expect(harvester.author_uid(author, wos_uids.second)).to eq pub_2
        end

        it 'creates new Contribution' do
          # NOTE: new source record not added when matching pub already found
          expect { harvester.author_uid(author, wos_uids.first) }
            .to change { author.contributions.count }.from(1).to(2)
            .and change { pub_1.contributions.count }.from(0).to(1)
            .and not_change { pub_2.contributions.count }
          expect(author.publications.reload.map(&:wos_uid)).to include(*wos_uids)
        end
      end
    end
  end

  context 'when author query has too many publications' do
    let(:lotsa_uids) { Array(1..Settings.WOS.max_publications_per_author) }
    let(:query_author) { instance_double(WebOfScience::QueryAuthor, uids: lotsa_uids, valid?: true) }

    before do
      allow(WebOfScience::QueryAuthor).to receive(:new).with(author, {}).and_return(query_author)
    end

    it 'aborts the harvest and returns no uids' do
      expect(NotificationManager).to receive(:error).with(
        ::Harvester::Error,
        "WebOfScience::Harvester - WoS harvest returned more than #{Settings.WOS.max_publications_per_author} " \
          "publications for author id #{author.id} and was aborted",
        harvester
      )
      expect(harvester.process_author(author)).to eq([])
      expect(author.contributions.size).to eq 0
    end
  end

  context 'when author query is invalid' do
    let(:query_author) { instance_double(WebOfScience::QueryAuthor) }

    before do
      allow(WebOfScience::QueryAuthor).to receive(:new).with(author, {}).and_return(query_author)
      allow(query_author).to receive('valid?').and_return(false)
    end

    it 'aborts the harvest and returns no uids' do
      expect(NotificationManager).to receive(:error).with(
        ::Harvester::Error,
        "WebOfScience::Harvester - An invalid author query was detected for author id #{author.id} and was aborted",
        harvester
      )
      expect(harvester.process_author(author)).to eq([])
      expect(author.contributions.size).to eq 0
    end
  end
end
