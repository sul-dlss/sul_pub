
describe DoiSearch do
  let(:doi_value) { '10.1016/j.mcn.2012.03.007' }
  let(:doi_identifier) do
    FactoryBot.create(:publication_identifier,
                       identifier_type: 'doi',
                       identifier_value: doi_value,
                       identifier_uri: "http://dx.doi.org/#{doi_value}")
  end

  before(:each) do
    doi_identifier.publication.save
  end

  describe '.search' do
    it 'returns one document ' do
      VCR.use_cassette('doi_search_spec_one_doc') do
        result = DoiSearch.search doi_value

        expect(result.size).to eq 1
        expect(result.first[:sw_id]).to eq '60813767'
      end
    end

    it 'queries sciencewire if the locally found pub is non-sciencewire' do
      VCR.use_cassette('doi_search_manual_doi_local') do
        doi_identifier.publication.pub_hash.update(provenance: 'cap')
        doi_identifier.publication.save
        expect(ScienceWireClient).to receive(:new).and_call_original
        result = DoiSearch.search doi_value
        expect(result.size).to eq 1
        expect(result.first[:provenance]).to eq 'sciencewire'
      end
    end
  end
end
