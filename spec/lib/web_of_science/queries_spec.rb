# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WebOfScience::Queries do
  include Savon::SpecHelper

  subject(:wos_queries) { described_class.new }

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  let(:wos_ids) { %w(WOS:A1976BW18000001 WOS:A1972N549400003) }
  let(:wos_retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response.xml') }
  let(:wos_retrieve_by_id_PMID) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response_MEDLINE26776186.xml') }
  let(:wos_search_by_doi_response) { File.read('spec/fixtures/wos_client/wos_search_by_doi_response.xml') }
  let(:wos_search_by_doi_mismatch_response) { File.read('spec/fixtures/wos_client/wos_search_by_doi_mismatch_response.xml') }
  let(:wos_search_custom_response) { File.read('spec/fixtures/wos_client/wos_search_custom_response.xml') }
  let(:wos_search_failure_response) { File.read('spec/fixtures/wos_client/wos_search_failure_response.xml') }

  let(:name) { "#{ln}, #{fn}" }
  let(:ln) { 'Lastname' }
  let(:fn) { 'Firstname' }

  let(:wos_auth_response) { File.read('spec/fixtures/wos_client/authenticate.xml') }
  before do
    wos_client = WebOfScience::Client.new('secret')
    allow(WebOfScience).to receive(:client).and_return(wos_client)
  end

  describe '#new' do
    it 'works' do
      instance = described_class.new
      expect(instance).to be_an described_class
    end
    it 'returns a WebOfScience::Retriever' do
      params = wos_queries.params_for_search("TI=This wonderful life")
      retriever = wos_queries.search(params)
      expect(retriever).to be_an WebOfScience::Retriever
    end
  end

  describe '#search_by_doi' do
    let(:doi) { '10.1007/s12630-011-9462-1' }
    let(:doi_mismatch) { '10.1007/s12630-011' }

    before do
      savon.expects(:authenticate).returns(wos_auth_response)
    end

    it 'works' do
      savon.expects(:search).with(message: :any).returns(wos_search_by_doi_response)
      retriever = wos_queries.search_by_doi(doi)
      expect(retriever).to be_an WebOfScience::Retriever
      expect(retriever.next_batch.count).to eq 1
    end
    it 'returns nothing for partial matches' do
      savon.expects(:search).with(message: :any).returns(wos_search_by_doi_mismatch_response)
      retriever = wos_queries.search_by_doi(doi_mismatch)
      expect(retriever).to be_an WebOfScience::Retriever
      expect(retriever.next_batch.count).to eq 10
    end
  end

  describe '#search with valid query' do
    let(:title) { 'A research roadmap for next-generation sequencing informatics' }
    let(:query) { "TI=#{title}" }
    let(:params) { wos_queries.params_for_search(query) }
    let(:retriever) { wos_queries.search(params) }

    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_custom_response)
    end
    it 'returns publication(s)' do
      expect(retriever.next_batch.count >= 1).to be true
    end
    it 'returns a publication matching the query' do
      expect(retriever.next_batch.doc.search('titles').text).to include title
    end
  end

  describe '#search with invalid query' do
    it 'raises Savon::SOAPFault' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_failure_response)
      params = wos_queries.params_for_search("TI=A messed up query & PY=2017")
      retriever = wos_queries.search(params)
      expect { retriever.next_batch }.to raise_error Savon::SOAPFault
    end
  end

  describe '#retrieve_by_id' do
    it 'works' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response)
      retriever = wos_queries.retrieve_by_id(wos_ids)
      expect(retriever).to be_an WebOfScience::Retriever
      expect(retriever.next_batch.uids).to eq(wos_ids)
    end
  end

  describe '#retrieve_by_pmid' do
    it 'works' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_PMID)
      retriever = wos_queries.retrieve_by_pmid(['26776186'])
      expect(retriever).to be_an WebOfScience::Retriever
      expect(retriever.next_batch.count).to eq(1)
    end
  end

  shared_examples 'search_params' do
    let(:query) { params[:queryParameters] }
    let(:retrieve) { params[:retrieveParameters] }

    it 'works' do
      expect(params).to include(queryParameters: Hash, retrieveParameters: Hash)
    end
    it 'has queryParameters' do
      expect(query).to include(databaseId: String, userQuery: String, queryLanguage: String)
    end
    it 'has retrieveParameters' do
      expect(retrieve).to include(firstRecord: Integer, count: Integer, option: Array)
    end
  end

  describe '#params_for_search' do
    let(:params) { wos_queries.params_for_search }

    it_behaves_like 'search_params'
  end

  describe '#params_for_fields' do
    let(:fields) { [{ collectionName: "WOS", fieldName: [""] }, { collectionName: "MEDLINE", fieldName: [""] }] }
    let(:params) { wos_queries.params_for_fields(fields) }

    it_behaves_like 'search_params'
    it 'has retrieveParameters with a viewField' do
      expect(params[:retrieveParameters]).to include(viewField: Array)
    end
  end
end
