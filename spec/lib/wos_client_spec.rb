# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WosClient do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  let(:wos_auth) { 'secret' }
  let(:wos_client) { described_class.new(wos_auth) }
  let(:auth_xml) { File.read('spec/fixtures/wos_client/authenticate.xml') }

  describe '#new' do
    it 'works' do
      expect(wos_client).to be_an described_class
    end
  end

  describe '#auth' do
    it 'works' do
      result = wos_client.auth
      expect(result).to be_an Savon::Client
    end
  end

  describe '#authenticate' do
    it 'authenticates with the service' do
      savon.expects(:authenticate).returns(auth_xml)
      response = wos_client.authenticate
      expect(response).to be_successful
    end
  end

  describe '#search' do
    it 'works' do
      savon.expects(:authenticate).returns(auth_xml)
      result = wos_client.search
      expect(result).to be_an Savon::Client
    end
  end

  describe '#session_id' do
    it 'works' do
      savon.expects(:authenticate).returns(auth_xml)
      result = wos_client.session_id
      expect(result).to be_an String
      expect(result).to eq '2F669ZtP6fRizIymX8V'
    end
  end

  describe '#session_close' do
    before do
      savon.expects(:authenticate).returns(auth_xml)
      wos_client.session_id
    end
    it 'works' do
      savon.expects(:close_session).returns('')
      result = wos_client.session_close
      expect(result).to be_nil
    end
  end
end
