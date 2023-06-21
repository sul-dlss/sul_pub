# frozen_string_literal: true

describe WebOfScience do
  describe '#harvester' do
    it 'works' do
      result = described_class.harvester
      expect(result).to be_an WebOfScience::Harvester
    end
  end

  describe '#links_client' do
    it 'works' do
      result = described_class.links_client
      expect(result).to be_an Clarivate::RestLinksClient
    end
  end

  describe '#client' do
    it 'works' do
      result = described_class.client
      expect(result).to be_an Clarivate::RestClient
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
end
