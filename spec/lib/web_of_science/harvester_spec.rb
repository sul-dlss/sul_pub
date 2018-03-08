# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WebOfScience::Harvester do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  subject(:harvester) { described_class.new }

  let(:author) { create :russ_altman }

  # WOS:A1976BW18000001 WOS:A1972N549400003 are in the wos_retrieve_by_id_response.xml
  let(:wos_uids) { %w(WOS:A1976BW18000001 WOS:A1972N549400003) }
  # let(:wos_rec) { WebOfScience::Record.new(record: File.read('spec/fixtures/wos_client/wos_record_A1976BW18000001.xml')) }
  let(:wos_harvest_author_name_response) { File.read('spec/fixtures/wos_client/wos_harvest_author_name_response.xml') }
  let(:wos_retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response.xml') }
  let(:any_records_will_do) do
    WebOfScience::Records.new(encoded_records: File.read('spec/fixtures/wos_client/medline_encoded_records.html'))
  end
  let(:wos_client) { WebOfScience::Client.new('secret') }

  before do
    allow(WebOfScience).to receive(:client).and_return(wos_client)
    savon.expects(:authenticate).returns(File.read('spec/fixtures/wos_client/authenticate.xml'))
  end

  shared_examples 'it_can_process_records' do
    it 'creates new WebOfScienceSourceRecord and author.contributions' do
      expect { harvest_process }.to change { [WebOfScienceSourceRecord.count, author.contributions.count] }
    end
  end

  describe '#harvest' do
    before do
      savon.expects(:search).with(message: :any).returns(wos_harvest_author_name_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response)
    end

    let(:harvest_process) { harvester.harvest([author]) }

    it_behaves_like 'it_can_process_records'

    it 'logs exceptions for processing an author' do
      processor = WebOfScience::ProcessRecords.new(author, any_records_will_do)
      allow(processor).to receive(:execute).and_raise(RuntimeError)
      allow(WebOfScience::ProcessRecords).to receive(:new).and_return(processor)
      expect(NotificationManager).to receive(:error)
      harvest_process
    end
  end

  describe '#harvest with existing publication and/or contribution data' do
    let(:wos_rec) { WebOfScience::Record.new(record: File.read('spec/fixtures/wos_client/wos_record_A1972N549400003.xml')) }
    let(:pub_A1972N549400003) do
      Publication.new(active: true, pub_hash: wos_rec.pub_hash, wos_uid: wos_rec.uid) do |pub|
        pub.sync_publication_hash_and_db # callbacks create PublicationIdentifiers etc.
        pub.save!
        pub.contributions.find_or_create_by!(
          author_id: author.id, cap_profile_id: author.cap_profile_id,
          featured: false, status: 'new', visibility: 'private'
        )
      end
    end
    let(:harvest_process) { harvester.harvest([author]) }

    before do
      # create one of the publications, without any contributions
      expect(pub_A1972N549400003).to be_persisted
      savon.expects(:search).with(message: :any).returns(wos_harvest_author_name_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(File.read('spec/fixtures/wos_client/wos_record_A1976BW18000001_response.xml'))
    end

    it 'processes records that have no publication' do
      # Use a new record WITHOUT a publication for WOS:A1976BW18000001, from wos_retrieve_by_id_response.xml
      expect { harvest_process }.to change { Publication.find_by(wos_uid: 'WOS:A1976BW18000001') }
    end
  end

  describe 'searching methods' do
    before { savon.expects(:search).with(message: :any).returns(search_response) }

    describe '#process_author' do
      before { savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response) }
      let(:search_response) { wos_harvest_author_name_response }
      let(:harvest_process) { harvester.process_author(author) }
      it_behaves_like 'it_can_process_records'
    end

    describe '#process_dois' do
      let(:search_response) { File.read('spec/fixtures/wos_client/wos_search_by_doi_response.xml') }
      # don't care if this actually belongs to the author or not
      let(:harvest_process) { harvester.process_dois(author, ['10.1007/s12630-011-9462-1']) }
      it_behaves_like 'it_can_process_records'
    end
  end

  describe 'retrieving methods' do
    before { savon.expects(:retrieve_by_id).with(message: :any).returns(retrieve_response) }

    describe '#process_pmids' do
      let(:retrieve_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response_MEDLINE26776186.xml') }
      let(:harvest_process) { harvester.process_pmids(author, ['26776186']) }
      it_behaves_like 'it_can_process_records'
    end

    describe '#process_uids' do
      let(:retrieve_response) { wos_retrieve_by_id_response }
      let(:harvest_process) { harvester.process_uids(author, wos_uids) }
      it_behaves_like 'it_can_process_records'
    end
  end
end
