# frozen_string_literal: true

# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'
require_relative 'wsdl'

describe WebOfScience::Client, :vcr do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }

  after(:all)  { savon.unmock! }

  let(:wos_auth) { 'secret' }
  let(:wos_client) { described_class.new(wos_auth) }
  let(:auth_xml) { File.read('spec/fixtures/wos_client/authenticate.xml') }
  let(:no_session_matches) { File.read('spec/fixtures/wos_client/wos_session_close_fault_response.xml') }

  before do
    WebOfScience::WSDL.stub_auth_wsdl
    WebOfScience::WSDL.stub_search_wsdl
    null_logger = Logger.new('/dev/null')
    allow(wos_client).to receive(:logger).and_return(null_logger)
  end

  describe '#new' do
    it 'works' do
      expect(wos_client).to be_a described_class
    end
  end

  describe '#auth' do
    it 'works' do
      expect(wos_client.auth).to be_a Savon::Client
    end
  end

  describe '#authenticate' do
    it 'authenticates with the service' do
      savon.expects(:authenticate).returns(auth_xml)
      expect(wos_client.authenticate).to be_successful
    end
  end

  describe '#search' do
    it 'works' do
      savon.expects(:authenticate).returns(auth_xml)
      expect(wos_client.search).to be_a Savon::Client
    end
  end

  describe '#session_id' do
    it 'works' do
      savon.expects(:authenticate).returns(auth_xml)
      result = wos_client.session_id
      expect(result).to be_a String
      expect(result).to eq '2F669ZtP6fRizIymX8V'
    end
  end

  describe '#session_close' do
    before do
      savon.expects(:authenticate).returns(auth_xml)
      wos_client.session_id
    end

    it 'resets the client' do
      savon.expects(:close_session).returns('')
      expect { wos_client.session_close }
        .to change { wos_client.instance_variable_get('@session_id') }
      expect(wos_client.instance_variable_get('@auth')).to be_nil
      expect(wos_client.instance_variable_get('@search')).to be_nil
      expect(wos_client.instance_variable_get('@session_queries')).to eq 0
    end

    context 'when there are no matches returned for SessionID' do
      let(:null_logger) { Logger.new('/dev/null') }

      before { savon.expects(:close_session).returns(no_session_matches) }

      it 'creates a logger and works' do
        expect(wos_client).to receive(:logger).and_return(null_logger)
        expect { wos_client.session_close }
          .to change { wos_client.instance_variable_get('@session_id') }
      end
    end
  end
end
