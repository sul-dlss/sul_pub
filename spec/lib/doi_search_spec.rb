# frozen_string_literal: true

describe DoiSearch do
  let(:doi_value) { '10.1016/j.mcn.2012.03.007' }
  let(:doi_identifier) { create(:doi_pub_id, identifier_value: doi_value) }

  before do
    doi_identifier.publication.wos_uid = '12345'
    doi_identifier.publication.save
    allow(Settings.WOS).to receive(:enabled).and_return(false) # default
  end

  describe '.search' do
    subject(:result) { described_class.search(doi_value) }

    shared_examples 'sciencewire one hit' do
      it 'returns Array of one document (Hash)' do
        expect(result).to match [a_hash_including(sw_id: '60813767', provenance: 'sciencewire')]
      end
    end

    context 'WOS disabled' do
      it 'only searches locally, returning Array of one Publication' do
        expect(WebOfScience).not_to receive(:queries)
        expect(described_class.search(doi_value)).to eq([doi_identifier.publication.pub_hash])
      end
    end

    context 'WOS enabled', :vcr do
      before { allow(Settings.WOS).to receive(:enabled).and_return(true) }

      context 'local hit found' do
        let(:publication) { doi_identifier.publication }

        before { expect(Publication).to receive(:find_by_doi).with(doi_value).and_return(publication) }

        it 'never queries WOS, if authoritative' do
          allow(publication).to receive(:wos_pub?).and_return(true)
          expect(WebOfScience).not_to receive(:queries)
          described_class.search(doi_value)
        end
        it 'queries WOS, if not authoritative' do
          allow(publication).to receive(:wos_pub?).and_return(false)
          described_class.search(doi_value)
        end
      end

      it 'without a local hit, queries WOS' do
        expect(Publication).to receive(:find_by_doi).with(doi_value).and_return(nil)
        expect(WebOfScience).to receive(:queries).and_call_original
        wos_matches = described_class.search(doi_value)
        wos_pub_hash = wos_matches.first
        expect(wos_pub_hash[:doi]).to eq doi_value
        expect(wos_pub_hash[:wos_uid]).to eq 'WOS:000305547700005'
      end
    end
  end

  # private methods

  describe '.doi_name' do
    it 'does not alter conventional DOIs' do
      expect(described_class.send(:doi_name, doi_value)).to eq doi_value
    end
    it 'returns nil for invalid DOIs' do
      expect(described_class.send(:doi_name, '10.1038/')).to be_nil
      expect(described_class.send(:doi_name, '')).to be_nil
      expect(described_class.send(:doi_name, nil)).to be_nil
    end
    it 'returns normalized DOI for full URI' do
      expect(described_class.send(:doi_name, 'https://doi.org/10.1038/ncomms3199')).to eq '10.1038/ncomms3199'
    end
  end
end
