# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WosQueries do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  let(:wos_auth_response) { File.read('spec/fixtures/wos_client/authenticate.xml') }
  let(:wos_auth) { 'secret' }
  let(:wos_client) { WosClient.new(wos_auth) }
  let(:wos_queries) { described_class.new(wos_client) }
  let(:wos_ids) { %w(WOS:A1976BW18000001 WOS:A1972N549400003) }
  let(:wos_name_search_response) { File.read('spec/fixtures/wos_client/wos_name_search_response.xml') }
  let(:wos_search_by_doi_response) { File.read('spec/fixtures/wos_client/wos_search_by_doi_response.xml') }
  let(:wos_retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response.xml') }

  let(:name) { "#{ln}, #{fn}" }
  let(:ln) { 'Lastname' }
  let(:fn) { 'Firstname' }
  let(:institutions) { wos_queries.send(:institutions) }

  describe '#new' do
    it 'works' do
      result = described_class.new(wos_client)
      expect(result).to be_an described_class
    end
  end

  describe '#search_by_doi' do
    let(:doi) { '10.1007/s12630-011-9462-1' }

    it 'works' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_search_by_doi_response)
      result = wos_queries.search_by_doi(doi)
      expect(result).to be_an WosRecords
      expect(result.count).to eq 1
    end
  end

  describe '#search_by_name' do
    it 'works' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:search).with(message: :any).returns(wos_name_search_response)
      result = wos_queries.search_by_name(name)
      expect(result).to be_an WosRecords
    end
  end

  describe '#retrieve_by_id' do
    it 'works' do
      savon.expects(:authenticate).returns(wos_auth_response)
      savon.expects(:retrieve_by_id).with(message: :any).returns(wos_retrieve_by_id_response)
      result = wos_queries.retrieve_by_id(wos_ids)
      expect(result).to be_an WosRecords
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

  describe '#institutions' do
    it 'works' do
      expect(institutions).to be_an Array
      expect(institutions.first).to be_an String
    end
  end

  describe '#search_by_name_params' do
    let(:search_by_name_params) { wos_queries.send(:search_by_name_params, name) }
    let(:query_params) { search_by_name_params[:queryParameters] }
    let(:user_query) { query_params[:userQuery] }

    it 'works' do
      expect(search_by_name_params).to be_an Hash
    end
    it 'includes first name' do
      expect(user_query).to include fn
    end
    it 'includes last name' do
      expect(user_query).to include ln
    end
    it 'includes institutions' do
      expect(user_query).to include institutions.sample
    end
  end
end
