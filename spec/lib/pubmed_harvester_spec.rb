require 'spec_helper'
SingleCov.covered!

describe PubmedHarvester, :vcr do
  let(:author) { FactoryGirl.create :author }

  let(:pub_hash) do
    {
      title: 'some title',
      year: 1938,
      issn: '32242424',
      pages: '34-56',
      author: [{ name: 'jackson joe' }],
      authorship: [{ sul_author_id: author.id, status: 'denied', visibility: 'public', featured: true }],
      identifier: [{ type: 'x', id: 'y', url: 'z' }]
    }
  end

  let(:publication) do
    FactoryGirl.create :pub_with_sw_id_and_pmid, pub_hash: pub_hash
  end

  before(:each) do
    publication
  end

  describe '.search_all_sources_by_pmid' do
    it 'searches for a local Publication by pmid and returns a pubhash' do
      h = PubmedHarvester.search_all_sources_by_pmid 10_048_354
      expect(h.first[:issn]).to eq '32242424'
    end

    it 'searches ScienceWire by pmid when not found locally and returns a pubhash' do
      h = PubmedHarvester.search_all_sources_by_pmid 10_487_815
      expect(h.first[:sw_id]).to eq '10340243'
      expect(h.first[:chicago_citation]).to match(/Convergence and Correlations/)
    end

    it 'searches Pubmed by pmid if not found in ScienceWire and returns a pubhash' do
      skip 'find an example pubmid not yet in sw'
      # This pmid might eventually show up in SW.  If that's the case, search the recent production logs for publication sourcelookups with this format:
      # /publications/sourcelookup?pmid=
      h = PubmedHarvester.search_all_sources_by_pmid 24_930_130
      expect(h.first[:provenance]).to eq('pubmed')
      expect(h.first[:identifier]).to include(type: 'doi', id: '10.1038/nmeth.2999', url: 'http://dx.doi.org/10.1038/nmeth.2999')
      expect(h.first[:chicago_citation]).to match(/Chemically Defined Generation/)
    end

    context 'mix of local plus SW/pubmed results' do
      it 'filters out batch/manual pubs from the resultset if SW/pubmed records were found' do
        pub2 = Publication.new
        pub2.pub_hash = pub_hash
        pub2.pub_hash[:provanance] = 'batch'
        pub2.pmid = 10_487_815
        pub2.save

        h = PubmedHarvester.search_all_sources_by_pmid 10_487_815
        expect(h.size).to eq 1
        expect(h.first[:sw_id]).to eq '10340243'
      end

      it 'does not do any filtering with a resultset of 2 manual/batch pubs' do
        ph = pub_hash.clone
        ph[:provanance] = 'cap'
        publication.pmid = 99_999_999  # Pubmed ID that does not exist
        publication.pub_hash = ph
        publication.save

        pub2 = Publication.new
        pub2.pub_hash = pub_hash
        pub2.pub_hash[:title] = 'batch pub'
        pub2.pub_hash[:provanance] = 'batch'
        pub2.pmid = 99_999_999
        pub2.save

        h = PubmedHarvester.search_all_sources_by_pmid 99_999_999
        expect(h.size).to eq 2
        expect(h.map { |hash| hash[:title] }).to include('batch pub', 'some title')
      end
    end
  end
end
