describe PubmedHarvester, :vcr do
  let(:author) { create :author }
  let(:pub_hash) do
    {
      title: 'some title',
      year: 1938,
      issn: '32242424',
      pages: '34-56',
      author: [{ name: 'jackson joe' }],
      authorship: [{ sul_author_id: author.id, status: 'denied', visibility: 'public', featured: true }],
      identifier: [{ type: 'x', id: 'y', url: 'z' }],
      provenance: 'pubmed'
    }
  end
  let!(:publication) { create(:publication, pmid: 10_048_354, pub_hash: pub_hash) }

  before(:each) do
    allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(true) # default
    allow(Settings.WOS).to receive(:enabled).and_return(false) # default
  end

  describe '.search_all_sources_by_pmid' do
    it 'searches for a local Publication by pmid and returns a pubhash' do
      expect(ScienceWireClient).not_to receive(:new)
      expect(PubmedClient).not_to receive(:new)
      h = PubmedHarvester.search_all_sources_by_pmid(10_048_354)
      expect(h.size).to eq 1
      expect(h.first[:issn]).to eq '32242424'
    end

    it 'searches ScienceWire by pmid when not found locally and returns a pubhash' do
      h = PubmedHarvester.search_all_sources_by_pmid(10_487_815)
      expect(h.size).to eq 1
      expect(h.first[:sw_id]).to eq '10340243'
      expect(h.first[:chicago_citation]).to match(/Convergence and Correlations/)
    end

    it 'searches Pubmed by pmid if not found in ScienceWire and returns a pubhash' do
      skip 'find an example pubmid not yet in sw'
      # This pmid might eventually show up in SW.  If that's the case, search the recent production logs for publication sourcelookups with this format:
      # /publications/sourcelookup?pmid=
      h = PubmedHarvester.search_all_sources_by_pmid(24_930_130)
      expect(h.first[:provenance]).to eq('pubmed')
      expect(h.first[:identifier]).to include(type: 'doi', id: '10.1038/nmeth.2999', url: 'https://dx.doi.org/10.1038/nmeth.2999')
      expect(h.first[:chicago_citation]).to match(/Chemically Defined Generation/)
    end

    context 'mix of local plus SW/pubmed results' do
      it 'filters out batch/manual pubs from the resultset if SW/pubmed records were found' do
        Publication.create!(
          pub_hash: pub_hash.merge(provenance: 'batch'),
          pmid: 10_487_815
        )
        expect(PubmedClient).not_to receive(:new)
        h = PubmedHarvester.search_all_sources_by_pmid(10_487_815)
        expect(h.size).to eq 1
        expect(h.first[:sw_id]).to eq '10340243'
      end

      it 'does not do any filtering with a resultset of 2 manual/batch pubs' do
        publication.pmid = 99_999_999 # Pubmed ID that does not exist
        publication.pub_hash = pub_hash.merge(provenance: 'cap')
        publication.save!
        Publication.create!(
          pub_hash: pub_hash.merge(title: 'batch pub', provenance: 'batch'),
          pmid: 99_999_999
        )
        h = PubmedHarvester.search_all_sources_by_pmid(99_999_999)
        expect(h.size).to eq 2
        expect(h.map { |hash| hash[:title] }).to include('batch pub', 'some title')
      end
    end
  end
end
