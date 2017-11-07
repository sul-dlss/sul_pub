# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WebOfScience::Harvester do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  subject(:harvester) { described_class.new }

  let(:wos_auth_response) { File.read('spec/fixtures/wos_client/authenticate.xml') }
  let(:wos_queries) do
    wos_client = WebOfScience::Client.new('secret')
    WebOfScience::Queries.new(wos_client)
  end

  let(:wos_uids) { %w(WOS:A1976BW18000001 WOS:A1972N549400003) }
  let(:wos_retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response.xml') }
  let(:wos_search_by_doi_response) { File.read('spec/fixtures/wos_client/wos_search_by_doi_response.xml') }
  let(:wos_search_by_name_response) { File.read('spec/fixtures/wos_client/wos_search_by_name_response.xml') }

  let(:medline_xml) { File.read('spec/fixtures/wos_client/medline_encoded_records.html') }
  let(:any_records_will_do) { WebOfScience::Records.new(encoded_records: medline_xml) }

  let(:author) do
    # public data from
    # - https://stanfordwho.stanford.edu
    # - https://med.stanford.edu/profiles/russ-altman
    author = FactoryGirl.create(:author,
                                 preferred_first_name: 'Russ',
                                 preferred_last_name: 'Altman',
                                 preferred_middle_name: 'Biagio',
                                 email: 'Russ.Altman@stanford.edu',
                                 cap_import_enabled: true)
    # create some `author.alternative_identities`
    FactoryGirl.create(:author_identity,
                       author: author,
                       first_name: 'R',
                       middle_name: 'B',
                       last_name: 'Altman',
                       email: nil,
                       institution: 'Stanford University')
    FactoryGirl.create(:author_identity,
                       author: author,
                       first_name: 'Russ',
                       middle_name: nil,
                       last_name: 'Altman',
                       email: nil,
                       institution: nil)
    author
  end

  before do
    allow(described_class).to receive(:wos_queries).and_return(wos_queries)
  end

  shared_examples 'it_can_process_records' do
    let(:processor) { WebOfScience::ProcessRecords.new(author, any_records_will_do) }

    before do
      allow(WebOfScience::ProcessRecords).to receive(:new).and_return(processor)
    end

    it 'works' do
      expect(processor).to receive(:execute).and_return(['WOS-UID'])
      harvest_process
    end
  end

  describe '#process_author' do
    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_by_name_response)
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
      #TODO: savon.expects(:search).with(message: :any).returns(wos_search_by_pmid_response)
    end

    let(:pmid) { 'A PMID' } # don't care if this actually belongs to the author or not
    let(:harvest_process) { harvester.process_pmids(author, [pmid]) }

    # TODO: it_behaves_like 'it_can_process_records'
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
