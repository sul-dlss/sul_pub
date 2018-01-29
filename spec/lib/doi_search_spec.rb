describe DoiSearch do
  let(:other_doi) { '10.1038/psp.2013.66' }
  let(:doi_value) { '10.1016/j.mcn.2012.03.007' }
  let(:doi_identifier) { create(:doi_pub_id, identifier_value: doi_value) }
  let(:wos_html) { File.read('spec/fixtures/wos_client/medline_encoded_records.html') }
  let(:wos_records) { WebOfScience::Records.new(encoded_records: wos_html) }

  before(:each) do
    doi_identifier.publication.save
    allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(false) # default
    allow(Settings.WOS).to receive(:enabled).and_return(false) # default
  end

  describe '.search' do
    subject(:result) { described_class.search(doi_value) }

    shared_examples 'sciencewire one hit' do
      it 'returns Array of one document (Hash)' do
        expect(result).to match [a_hash_including(sw_id: '60813767', provenance: 'sciencewire')]
      end
    end

    context 'ScienceWire and WOS both disabled' do
      it 'only searches locally, returning Array of one Publication' do
        expect(ScienceWireClient).not_to receive(:new)
        expect(WebOfScience).not_to receive(:queries)
        expect(described_class.search(doi_value)).to eq([doi_identifier.publication.pub_hash])
      end
    end

    context 'ScienceWire enabled, WOS disabled', :vcr do
      before { allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(true) }

      VCR.use_cassette('doi_search_spec_one_doc') do
        it_behaves_like 'sciencewire one hit'
        it 'queries sciencewire if the local pub match is not DOI-reliable' do
          doi_identifier.publication.pub_hash[:provenance] = 'cap'
          doi_identifier.publication.save!
          expect(ScienceWireClient).to receive(:new).and_call_original
          expect(result.size).to eq 1
          expect(result.first[:provenance]).to eq 'sciencewire'
        end
      end
    end

    context 'ScienceWire disabled, WOS enabled' do
      before do
        allow(Settings.WOS).to receive(:enabled).and_return(true)
        expect(ScienceWireClient).not_to receive(:new)
      end

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
          expect(WebOfScience.queries).to receive(:search_by_doi).with(doi_value).and_return([])
          described_class.search(doi_value)
        end
      end

      it 'without a local hit, queries WOS' do
        expect(WebOfScience.queries).to receive(:search_by_doi).with(other_doi).and_return([])
        expect(described_class.search(other_doi)).to eq []
      end
    end
  end

  # private methods

  describe '.normalized_doi' do
    it 'does not alter conventional DOIs' do
      expect(described_class.send(:normalized_doi, doi_value)).to eq doi_value
    end
    it 'returns nil for invalid DOIs' do
      expect(described_class.send(:normalized_doi, '10.1038/')).to be_nil
      expect(described_class.send(:normalized_doi, '')).to be_nil
      expect(described_class.send(:normalized_doi, nil)).to be_nil
    end
    it 'returns normalized DOI for full URI' do
      expect(described_class.send(:normalized_doi, 'http://dx.doi.org/10.1038/ncomms3199')).to eq '10.1038/ncomms3199'
    end
  end

  describe '.normalized_dois' do
    subject(:result) { described_class.send(:normalized_dois, wos_records.map(&:pub_hash)) }

    it 'returns a hash with only authoritative DOI keys mapped to hashes' do
      expect(wos_records.count).to eq 5 # the fixture has many records
      expect(result.count).to eq 1
      expect(result).to match a_hash_including(other_doi => a_hash_including(doi: other_doi))
    end
  end
end
