require 'spec_helper'
SingleCov.covered!

describe DoiSearch do
  let(:publication) { create :publication }
  let(:author) { create :author }

  before(:each) do
    publication
  end

  describe '.search' do
    it 'returns one document ' do
      VCR.use_cassette('doi_search_spec_one_doc') do
        result = DoiSearch.search '10.1016/j.mcn.2012.03.007'

        expect(result.size).to eq 1
        expect(result.first[:sw_id]).to eq '60813767'
      end
    end

    it 'queries sciencewire if the locally found pub is non-sciencewire' do
      VCR.use_cassette('doi_search_manual_doi_local') do
        publication.pub_hash = {
          provenance: 'cap',
          identifier: [{ type: 'doi', id: '10.1111/j.1444-0938.2010.00524.x', url: 'http://dx.doi.org/10.1111/j.1444-0938.2010.00524.x' }]
        }
        publication.sync_identifiers_in_pub_hash_to_db
        publication.save

        result = DoiSearch.search '10.1111/j.1444-0938.2010.00524.x'
        expect(result.size).to eq 1
        expect(result.first[:provenance]).to eq 'sciencewire'
      end
    end
  end
end
