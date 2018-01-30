# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WebOfScience::Harvester do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  subject(:harvester) { described_class.new }

  # WOS:A1976BW18000001 WOS:A1972N549400003 are in the wos_retrieve_by_id_response.xml
  let(:wos_uids) { %w(WOS:A1976BW18000001 WOS:A1972N549400003) }
  let(:wos_A1972N549400003) { File.read('spec/fixtures/wos_client/wos_record_A1972N549400003.xml') }
  let(:wos_A1976BW18000001) { File.read('spec/fixtures/wos_client/wos_record_A1976BW18000001.xml') }
  let(:rec_A1972N549400003) { WebOfScience::Record.new(record: wos_A1972N549400003) }
  let(:rec_A1976BW18000001) { WebOfScience::Record.new(record: wos_A1976BW18000001) }
  let(:wos_A1972N549400003_response) { File.read('spec/fixtures/wos_client/wos_record_A1972N549400003_response.xml') }
  let(:wos_A1976BW18000001_response) { File.read('spec/fixtures/wos_client/wos_record_A1976BW18000001_response.xml') }
  let(:wos_retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response.xml') }
  let(:wos_retrieve_by_id_records) do
    WebOfScience::Records.new(records: "<records>#{rec_A1972N549400003.to_xml}#{rec_A1976BW18000001.to_xml}</records>")
  end
  let(:wos_harvest_author_name_response) { File.read('spec/fixtures/wos_client/wos_harvest_author_name_response.xml') }

  let(:wos_search_by_doi_response) { File.read('spec/fixtures/wos_client/wos_search_by_doi_response.xml') }
  let(:wos_retrieve_by_id_PMID) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response_MEDLINE26776186.xml') }

  let(:medline_xml) { File.read('spec/fixtures/wos_client/medline_encoded_records.html') }
  let(:any_records_will_do) { WebOfScience::Records.new(encoded_records: medline_xml) }

  let(:author) do
    # public data from
    # - https://stanfordwho.stanford.edu
    # - https://med.stanford.edu/profiles/russ-altman
    author = FactoryBot.create(:author,
                                 preferred_first_name: 'Russ',
                                 preferred_last_name: 'Altman',
                                 preferred_middle_name: 'Biagio',
                                 email: 'Russ.Altman@stanford.edu',
                                 cap_import_enabled: true)
    # create some `author.alternative_identities`
    FactoryBot.create(:author_identity,
                       author: author,
                       first_name: 'R',
                       middle_name: 'B',
                       last_name: 'Altman',
                       email: nil,
                       institution: 'Stanford University')
    FactoryBot.create(:author_identity,
                       author: author,
                       first_name: 'Russ',
                       middle_name: nil,
                       last_name: 'Altman',
                       email: nil,
                       institution: nil)
    author
  end

  let(:wos_auth_response) { File.read('spec/fixtures/wos_client/authenticate.xml') }
  before do
    wos_client = WebOfScience::Client.new('secret')
    allow(WebOfScience).to receive(:client).and_return(wos_client)
  end

  shared_examples 'it_can_process_records' do
    it 'creates new WebOfScienceSourceRecord' do
      expect { harvest_process }.to change { WebOfScienceSourceRecord.count }
    end
    it 'creates new author.contributions' do
      expect { harvest_process }.to change { author.contributions.count }
    end
  end

  describe '#harvest' do
    before do
      savon.expects(:authenticate).returns(wos_auth_response)
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
    let(:contrib_A1972N549400003) do
      contrib = pub_A1972N549400003.contributions.find_or_initialize_by(
        author_id: author.id, cap_profile_id: author.cap_profile_id,
        featured: false, status: 'new', visibility: 'private'
      )
      contrib.save
      contrib
    end
    let(:pub_A1972N549400003) do
      pub = Publication.new(active: true, pub_hash: rec_A1972N549400003.pub_hash, wos_uid: rec_A1972N549400003.uid)
      pub.sync_publication_hash_and_db # callbacks create PublicationIdentifiers etc.
      pub.save!
      pub
    end
    let(:harvest_process) { harvester.harvest([author]) }

    before do
      # create one of the publications, without any contributions
      expect(pub_A1972N549400003.persisted?).to be true
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_harvest_author_name_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_A1976BW18000001_response)
    end

    it 'processes records that have no publication' do
      # Use a new record WITHOUT a publication for WOS:A1976BW18000001, from wos_retrieve_by_id_response.xml
      expect { harvest_process }.to change { Publication.find_by(wos_uid: 'WOS:A1976BW18000001') }
    end
  end

  describe '#process_author' do
    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_harvest_author_name_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response)
    end

    let(:harvest_process) { harvester.process_author(author) }

    it_behaves_like 'it_can_process_records'
  end

  describe '#process_dois' do
    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_by_doi_response)
    end

    let(:doi) { '10.1007/s12630-011-9462-1' } # don't care if this actually belongs to the author or not
    let(:harvest_process) { harvester.process_dois(author, [doi]) }

    it_behaves_like 'it_can_process_records'
  end

  describe '#process_pmids' do
    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_PMID)
    end

    let(:pmid) { '26776186' } # don't care if this actually belongs to the author or not
    let(:harvest_process) { harvester.process_pmids(author, [pmid]) }

    it_behaves_like 'it_can_process_records'
  end

  describe '#process_uids' do
    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response)
    end

    let(:harvest_process) { harvester.process_uids(author, wos_uids) }

    it_behaves_like 'it_can_process_records'
  end
end
