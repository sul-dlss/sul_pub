# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WebOfScience::Queries do
  include Savon::SpecHelper

  subject(:wos_queries) { described_class.new(wos_client) }

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  let(:wos_auth_response) { File.read('spec/fixtures/wos_client/authenticate.xml') }
  let(:wos_auth) { 'secret' }
  let(:wos_client) { WebOfScience::Client.new(wos_auth) }
  let(:wos_ids) { %w(WOS:A1976BW18000001 WOS:A1972N549400003) }
  let(:wos_retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response.xml') }
  let(:wos_retrieve_by_id_PMID) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response_MEDLINE26776186.xml') }
  let(:wos_search_by_doi_response) { File.read('spec/fixtures/wos_client/wos_search_by_doi_response.xml') }
  let(:wos_search_by_doi_mismatch_response) { File.read('spec/fixtures/wos_client/wos_search_by_doi_mismatch_response.xml') }
  let(:wos_search_by_name_response) { File.read('spec/fixtures/wos_client/wos_search_by_name_response.xml') }
  let(:wos_search_custom_response) { File.read('spec/fixtures/wos_client/wos_search_custom_response.xml') }
  let(:wos_search_failure_response) { File.read('spec/fixtures/wos_client/wos_search_failure_response.xml') }

  let(:name) { "#{ln}, #{fn}" }
  let(:ln) { 'Lastname' }
  let(:fn) { 'Firstname' }

  describe '.working?' do
    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      allow(described_class).to receive(:new).and_return(wos_queries)
    end
    context 'success' do
      it 'returns true when it works' do
        savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response)
        expect(described_class.working?).to be true
      end
    end
    context 'failure' do
      it 'raises exceptions when it fails' do
        savon.expects(:retrieve_by_id).with(message: :any).returns(wos_search_failure_response)
        expect { described_class.working? }.to raise_error(Savon::SOAPFault)
      end
    end
  end

  describe '#new' do
    it 'works' do
      result = described_class.new(wos_client)
      expect(result).to be_an described_class
    end
  end

  describe '#search_by_doi' do
    let(:doi) { '10.1007/s12630-011-9462-1' }
    let(:doi_mismatch) { '10.1007/s12630-011' }

    it 'works' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_by_doi_response)
      records = wos_queries.search_by_doi(doi)
      expect(records).to be_an WebOfScience::Records
      expect(records.count).to eq 1
    end
    it 'returns nothing for partial matches' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_by_doi_mismatch_response)
      records = wos_queries.search_by_doi(doi_mismatch)
      expect(records).to be_an WebOfScience::Records
      expect(records).to be_empty
    end
  end

  describe '#search with valid query' do
    let(:title) { 'A research roadmap for next-generation sequencing informatics' }
    let(:query) { "TI=#{title}" }
    let(:records) { wos_queries.search(query) }

    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_custom_response)
    end
    it 'works' do
      expect(records).to be_an WebOfScience::Records
    end
    it 'returns publication(s)' do
      expect(records.count >= 1).to be true
    end
    it 'returns a publication matching the query' do
      expect(records.doc.search('titles').text).to include title
    end
  end

  describe '#search with invalid query' do
    let(:title) { 'A messed up query' }
    let(:invalid_query) { "TI=#{title} & PY=2017" }
    let(:records) { wos_queries.search(invalid_query) }

    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_failure_response)
    end
    it 'raises Savon::SOAPFault' do
      expect { records }.to raise_error Savon::SOAPFault
    end
  end

  describe '#search_by_name' do
    let(:records) { wos_queries.search_by_name(name) }

    before do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_by_name_response)
    end
    it 'works' do
      expect(records).to be_an WebOfScience::Records
    end
    it 'returns many results' do
      expect(records.count > 1).to be true
    end
  end

  describe '#retrieve_by_id' do
    it 'works' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response)
      records = wos_queries.retrieve_by_id(wos_ids)
      expect(records).to be_an WebOfScience::Records
    end
  end

  describe '#retrieve_by_pmid' do
    it 'works' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_PMID)
      records = wos_queries.retrieve_by_pmid(['26776186'])
      expect(records).to be_an WebOfScience::Records
    end
  end

  # PRIVATE

  describe '#name_query' do
    let(:name_query) { wos_queries.send(:name_query, name) }

    it 'works' do
      expect(name_query).to be_an String
    end
    it 'includes first name' do
      expect(name_query).to include fn
    end
    it 'includes last name' do
      expect(name_query).to include ln
    end
  end
end
