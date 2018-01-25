describe DOI, :vcr do
  # Example data from http://www.doi.org/index.html
  let(:doi) { '10.1109/5.771073' }
  let(:doi_uri) { 'https://doi.org/10.1109/5.771073' }
  let(:doi_loc) { 'http://ieeexplore.ieee.org/document/771073/' } # this _could_ change

  describe '.doi_name' do
    it 'does not alter valid DOI values' do
      expect(described_class.doi_name(doi)).to eq doi
    end
    it 'returns normalized DOI for full URI' do
      expect(described_class.doi_name(doi_uri)).to eq doi
    end
    it 'returns nil for invalid DOI values' do
      expect(described_class.doi_name('10.1038/')).to be_nil
      expect(described_class.doi_name('')).to be_nil
      expect(described_class.doi_name(nil)).to be_nil
    end
    it 'returns nil for any exceptions' do
      expect(Identifiers::DOI).to receive(:extract).and_raise(RuntimeError)
      expect(described_class.doi_name(nil)).to be_nil
    end
  end

  describe '.doi_url' do
    it 'works' do
      expect(described_class.doi_url(doi)).not_to be_nil
    end
    it 'does not alter valid DOI URL' do
      expect(described_class.doi_url(doi_uri)).to eq doi_uri
    end
    it 'returns full URI for DOI value' do
      expect(described_class.doi_url(doi)).to eq doi_uri
    end
    it 'returns nil for invalid DOI values' do
      expect(described_class.doi_url('10.1038/')).to be_nil
      expect(described_class.doi_url(DOI::DOI_PREFIX + 'junk')).to be_nil
      expect(described_class.doi_url('')).to be_nil
      expect(described_class.doi_url(nil)).to be_nil
    end
  end

  context 'DOI services for validation' do
    let(:doi_url) { described_class.doi_url(doi) }

    describe '.doi_found?' do
      it 'is true if it can be found' do
        expect(described_class.doi_found?(doi_url)).to be true
      end
      it 'is false if it cannot be found' do
        expect(described_class.doi_found?(DOI::DOI_PREFIX + 'junk')).to be false
      end
    end
    describe '.doi_location' do
      it 'is a resolved URL if it can be found' do
        expect(described_class.doi_location(doi_url)).to eq doi_loc
      end
      it 'is nil if it cannot be found' do
        expect(described_class.doi_location(DOI::DOI_PREFIX + 'junk')).to be_nil
      end
    end
  end
end
