# See also spec/api/sul_bib/sourcelookup_spec.rb

describe PublicationsController do
  let(:author) { build :author }

  before { allow(controller).to receive(:check_authorization).and_return(true) }

  describe 'GET index' do
    let(:cap_id) { 'whatever' }
    it 'checks authorization' do
      expect(controller).to receive(:check_authorization)
      get :index, params: { capProfileId: cap_id, format: 'json' }
    end

    context 'with unknown capProfileId' do
      it 'returns a 404' do
        get :index, params: { capProfileId: cap_id, format: 'json' }
        expect(response.status).to eq 404
        expect(response.body).to include 'No such author'
      end
    end

    context 'with known capProfileId' do
      let(:json_response) { JSON.parse(response.body) }
      before { allow(Author).to receive(:find_by).with(cap_profile_id: cap_id).and_return(author) }

      it 'returns a structured response' do
        get :index, params: { capProfileId: cap_id, format: 'json' }
        expect(response.status).to eq 200
        expect(json_response).to match a_hash_including(
          'metadata' => a_hash_including('format' => 'BibJSON', 'page' => 1, 'per_page' => 1000, 'records' => '0'),
          'records' => []
        )
      end
    end
  end

  describe 'GET sourcelookup' do
    it 'checks authorization' do
      expect(controller).to receive(:check_authorization)
      allow(DoiSearch).to receive(:search).with('xyz').and_return([])
      get :sourcelookup, params: { doi: 'xyz', format: 'json' }
    end

    it 'raises exception if no important param received' do
      expect { get :sourcelookup }.to raise_error(ActionController::ParameterMissing)
      expect { get :sourcelookup, params: { year: 2001 } }.to raise_error(ActionController::ParameterMissing)
    end

    it 'with doi calls DoiSearch' do # and ignores pmid & title
      expect(DoiSearch).to receive(:search).with('xyz').and_return([])
      expect(PubmedHarvester).not_to receive(:search_all_sources_by_pmid)
      get :sourcelookup, params: { doi: 'xyz', pmid: 'abc', title: 'foo', format: 'json' }
    end

    it 'with pmid calls PubmedHarvester' do
      expect(PubmedHarvester).to receive(:search_all_sources_by_pmid).with('abc').and_return([])
      expect(DoiSearch).not_to receive(:search)
      get :sourcelookup, params: { pmid: 'abc', format: 'json' }
    end

    context 'title search' do
      let(:json_response) { JSON.parse(response.body) }

      before do
        allow(Settings.WOS).to receive(:enabled).and_return(false) # default
      end

      context 'WOS disabled' do
        let(:ussr) { create :user_submitted_source_record, title: 'Men On Mars', year: 2001, source_data: '{}' }
        let!(:pub) do
          pub = build(:publication, title: ussr.title, year: ussr.year, user_submitted_source_records: [ussr])
          pub.pub_hash[:year] = ussr.year # values will overwrite from pub_hash
          pub.pub_hash[:title] = ussr.title
          pub.save!
          ussr.publication = pub # association does not automatically update ussr
          ussr.save!
          pub
        end

        it 'only searches local/manual pubs' do
          expect(WebOfScience).not_to receive(:queries)
          get :sourcelookup, params: { title: 'en On Ma', format: 'json' } # Partial title
          expect(json_response).to match a_hash_including(
            'metadata' => a_hash_including('format' => 'BibJSON', 'page' => 1, 'per_page' => 'all', 'records' => '1'),
            'records' => [a_hash_including('title' => pub.title, 'year' => pub.year)]
          )
        end
      end

      context 'WOS enabled' do
        let(:queries) { instance_double(WebOfScience::Queries) }
        let(:retriever) { instance_double(WebOfScience::Retriever, next_batch: WebOfScience::Records.new(records: '<xml/>')) }
        before do
          allow(Settings.WOS).to receive(:enabled).and_return(true)
          allow(WebOfScience).to receive(:queries).and_return(queries)
        end

        it 'hits WOS' do
          expect(queries).to receive(:user_query).with('TI="xyz"').and_return(retriever)
          get :sourcelookup, params: { title: 'xyz', format: 'json' } # Partial title
        end
        it 'includes year if provided' do
          expect(queries).to receive(:user_query).with('TI="xyz" AND PY=2001').and_return(retriever)
          get :sourcelookup, params: { title: 'xyz', year: 2001, format: 'json' } # Partial title with year
        end
        it 'remove quotes from user query to avoid parsing errors' do
          expect(queries).to receive(:user_query).with('TI="xyz with quoted values in it"').and_return(retriever)
          get :sourcelookup, params: { title: 'xyz with "quoted values" in it', format: 'json' } # title with quotes
        end
      end
    end
  end
end
