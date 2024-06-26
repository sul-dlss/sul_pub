# frozen_string_literal: true

describe Pubmed::Fetcher, :vcr do
  let(:author) { create(:author) }
  let(:pub_hash) do
    {
      title: 'some title',
      year: '1938',
      issn: '32242424',
      pages: '34-56',
      author: [{ name: 'jackson joe' }],
      authorship: [{ sul_author_id: author.id, status: 'denied', visibility: 'public', featured: true }],
      identifier: [{ type: 'x', id: 'y', url: 'z' }],
      provenance: 'pubmed',
      type: 'article'
    }
  end

  before do
    allow(Settings.WOS).to receive(:enabled).and_return(false) # but not WOS
  end

  describe '.search_all_sources_by_pmid' do
    let!(:publication) { create(:publication, pmid: 10_048_354, pub_hash:) }

    it 'searches for a local Publication by pmid and returns a pubhash' do
      expect(Pubmed::Client).not_to receive(:new)
      h = described_class.search_all_sources_by_pmid(10_048_354)
      expect(h.size).to eq 1
      expect(h.first[:issn]).to eq '32242424'
    end

    it 'searches by pmid when not found locally and returns a pubhash' do
      h = described_class.search_all_sources_by_pmid(10_487_815)
      expect(h.size).to eq 1
      expect(h.first[:chicago_citation]).to match(/Convergence and Correlations/)
      expect(h.first).to include(pmid: '10487815')
    end

    it 'searches Pubmed by pmid if not found, returning a pubhash' do
      skip 'find an example pubmid not yet in sw'
      h = described_class.search_all_sources_by_pmid(24_930_130).first
      expect(h[:provenance]).to eq('pubmed')
      expect(h[:identifier]).to include(type: 'doi', id: '10.1038/nmeth.2999', url: 'https://doi.org/10.1038/nmeth.2999')
      expect(h[:chicago_citation]).to match(/Chemically Defined Generation/)
    end

    context 'local hits of varied provenance' do
      before { allow(described_class).to receive(:fetch_remote_pubmed).and_return([]) }

      it 'filters out batch/manual pubs from the resultset if previous SW/pubmed records were found' do
        Publication.create!(
          pub_hash: pub_hash.merge(provenance: 'batch'),
          pmid: 10_487_815
        )
        h = described_class.search_all_sources_by_pmid(10_487_815)
        expect(h.size).to eq 1
      end

      it 'returns an empty array when no pubs found anywhere' do
        h = described_class.search_all_sources_by_pmid('crap')
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
          h = described_class.search_all_sources_by_pmid(99_999_999)
          expect(h.size).to eq 1
        end
      end
    end
  end

  # private
  describe '.fetch_remote_pubmed' do
    subject(:hits) do
      described_class.send(:fetch_remote_pubmed, 24_930_130)
    end

    context 'Pubmed enabled and WOS disabled' do
      before do
        allow(Settings.WOS).to receive(:enabled).and_return(false)
        allow(Settings.PUBMED).to receive(:lookup_enabled).and_return(true)
      end

      it 'searches only pubmed' do
        expect(WebOfScience).not_to receive(:queries)
        expect(hits.size).to eq(1)
        expect(hits.first[:title]).to eq('Chemically defined generation of human cardiomyocytes.')
        expect(hits.first[:chicago_citation]).to match(/Chemically Defined Generation/)
      end
    end

    context 'Pubmed and WOS both enabled' do
      before do
        allow(Settings.WOS).to receive(:enabled).and_return(true)
        allow(Settings.PUBMED).to receive(:lookup_enabled).and_return(true)
      end

      it 'searches only WOS if a result is found there (and stops before hitting pubmed service)' do
        expect(Pubmed.client).not_to receive(:new)
        expect(hits.size).to eq(1)
        expect(hits.first[:title]).to eq('Chemically defined generation of human cardiomyocytes.')
        expect(hits.first[:chicago_citation]).to match(/Chemically Defined Generation/)
      end

      it 'searches Pubmed next if no results found at WoS' do
        expect(WebOfScience.queries).to receive(:retrieve_by_id)
          .with(['MEDLINE:24930130'])
          .and_return(instance_double(WebOfScience::IdQueryRestRetriever,
                                      next_batch: WebOfScience::Records.new(records: '<xml/>')))
        expect(Pubmed.client).to receive(:fetch_records_for_pmid_list)
          .and_return([])
        expect(hits).to eq([])
      end
    end

    context 'Pubmed and WOS both disabled' do
      before do
        allow(Settings.WOS).to receive(:enabled).and_return(false)
        allow(Settings.PUBMED).to receive(:lookup_enabled).and_return(false)
      end

      it 'searches nothing' do
        expect(WebOfScience).not_to receive(:queries)
        expect(Pubmed.client).not_to receive(:new)
        expect(hits.size).to eq(0)
      end
    end
  end
end
