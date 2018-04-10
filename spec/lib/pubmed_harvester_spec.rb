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

  before(:each) do
    allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(true) # legacy tests VCR'd w/ SW + PubMed
    allow(Settings.WOS).to receive(:enabled).and_return(false) # but not WOS
  end

  describe '.search_all_sources_by_pmid' do
    let!(:publication) { create(:publication, pmid: 10_048_354, pub_hash: pub_hash) }

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
      h = PubmedHarvester.search_all_sources_by_pmid(24_930_130).first
      expect(h[:provenance]).to eq('pubmed')
      expect(h[:identifier]).to include(type: 'doi', id: '10.1038/nmeth.2999', url: 'https://dx.doi.org/10.1038/nmeth.2999')
      expect(h[:chicago_citation]).to match(/Chemically Defined Generation/)
    end

    context 'local hits of varied provenance' do
      before { allow(PubmedHarvester).to receive(:fetch_remote_pubmed).and_return([]) }

      it 'filters out batch/manual pubs from the resultset if previous SW/pubmed records were found' do
        Publication.create!(
          pub_hash: pub_hash.merge(provenance: 'batch'),
          pmid: 10_487_815
        )
        h = PubmedHarvester.search_all_sources_by_pmid(10_487_815)
        expect(h.size).to eq 1
      end

      it 'returns an empty array when no pubs found anywhere' do
        h = PubmedHarvester.search_all_sources_by_pmid('crap')
        expect(h.size).to eq 0
      end

      context 'duplicate PMIDs' do
        before do
          publication.pmid = 99_999_999 # Pubmed ID that does not exist
          publication.pub_hash = pub_hash.merge(provenance: 'cap')
          publication.save!
          Publication.create!(
            pub_hash: pub_hash.merge(title: 'batch pub', provenance: 'batch'),
            pmid: 99_999_999
          )
        end

        it 'returns first of local matches' do
          h = PubmedHarvester.search_all_sources_by_pmid(99_999_999)
          expect(h.size).to eq 1
        end
      end
    end
  end

  # private
  describe '.fetch_remote_pubmed' do
    subject(:hits) { described_class.send(:fetch_remote_pubmed, 24_930_130) } # backed by VCR cassettes for each provider

    before(:each) do
      allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(false) # default
      allow(Settings.WOS).to receive(:enabled).and_return(false) # default
    end

    context 'WOS and ScienceWire, both disabled' do
      it 'searches only pubmed' do
        expect(ScienceWireClient).not_to receive(:new)
        expect(WebOfScience).not_to receive(:queries)
        expect(hits.size).to eq(1)
        expect(hits.first[:title]).to eq('Chemically defined generation of human cardiomyocytes.')
        expect(hits.first[:chicago_citation]).to match(/Chemically Defined Generation/)
      end
    end

    context 'WOS disabled, ScienceWire enabled' do
      before { allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(true) }

      it 'searches only ScienceWire' do
        expect(WebOfScience).not_to receive(:queries)
        expect(PubmedClient).not_to receive(:new)
        expect(hits.size).to eq(1)
        expect(hits.first[:title]).to eq('Chemically defined generation of human cardiomyocytes') # no period, meh
        expect(hits.first[:chicago_citation]).to match(/Chemically Defined Generation/)
      end
    end

    context 'WOS enabled, ScienceWire disabled' do
      before { allow(Settings.WOS).to receive(:enabled).and_return(true) }

      it 'searches only WOS' do
        expect(ScienceWireClient).not_to receive(:new)
        expect(PubmedClient).not_to receive(:new)
        expect(hits.size).to eq(1)
        expect(hits.first[:title]).to eq('Chemically defined generation of human cardiomyocytes.')
        expect(hits.first[:chicago_citation]).to match(/Chemically Defined Generation/)
      end
    end

    context 'Everything enabled' do
      before(:each) do
        allow(Settings.SCIENCEWIRE).to receive(:enabled).and_return(true)
        allow(Settings.WOS).to receive(:enabled).and_return(true)
      end

      it 'without hits, fails over across services' do
        expect(WebOfScience.queries).to receive(:retrieve_by_pmid)
          .with([24_930_130])
          .and_return(instance_double(WebOfScience::Retriever, next_batch: WebOfScience::Records.new(records: '<xml/>')))
        expect(PubmedClient).to receive(:new)
          .and_return(instance_double(PubmedClient, fetch_records_for_pmid_list: []))
        expect(ScienceWireClient).to receive(:new)
          .and_return(instance_double(ScienceWireClient, pull_records_from_sciencewire_for_pmids: Nokogiri::XML('<xml/>')))
        expect(hits).to eq([])
      end
    end
  end
end
