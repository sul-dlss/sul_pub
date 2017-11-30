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
    it 'works' do
      expect(Logger).to receive(:new).with(Settings.WOS.LOG).once.and_call_original
      expect(described_class.logger).to be_a Logger
    end
  end
end
