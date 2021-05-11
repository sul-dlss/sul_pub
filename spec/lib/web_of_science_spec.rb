# frozen_string_literal: true

# http://savonrb.com/version2/testing.html
# require the helper module
require 'savon/mock/spec_helper'

describe WebOfScience do
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock! }

  after(:all)  { savon.unmock! }

  describe '#harvester' do
    it 'works' do
      result = described_class.harvester
      expect(result).to be_an WebOfScience::Harvester
    end
  end

  describe '#links_client' do
    it 'works' do
      result = described_class.links_client
      expect(result).to be_an Clarivate::LinksClient
    end
  end

  describe '#client' do
    it 'works' do
      result = described_class.client
      expect(result).to be_an WebOfScience::Client
    end
  end

  describe '#queries' do
    it 'works' do
      result = described_class.queries
      expect(result).to be_an WebOfScience::Queries
    end
  end

  describe '#logger' do
    before do
      described_class.class_variable_set('@@logger', nil)
    end

    it 'works' do
      null_logger = Logger.new('/dev/null')
      expect(Logger).to receive(:new).with(Settings.WOS.LOG).once.and_return(null_logger)
      expect(described_class.logger).to be_a Logger
      expect(described_class.logger).to be_a Logger
    end
  end

  describe '.working?' do
    let(:wos_auth_response) { File.read('spec/fixtures/wos_client/authenticate.xml') }
    let(:wos_retrieve_by_id_response) { File.read('spec/fixtures/wos_client/wos_retrieve_by_id_response.xml') }
    let(:wos_search_failure_response) { File.read('spec/fixtures/wos_client/wos_search_failure_response.xml') }

    before do
      wos_client = WebOfScience::Client.new('secret')
      allow(WebOfScience::Client).to receive(:new).and_return(wos_client)
      described_class.class_variable_set(:@@client, nil)
      described_class.class_variable_set(:@@queries, nil)
      savon.expects(:authenticate).returns(wos_auth_response)
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
end
