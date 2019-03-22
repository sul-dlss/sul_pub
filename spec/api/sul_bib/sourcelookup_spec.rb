# TODO: move this file to spec/controllers/publications_controller_spec.rb

describe SulBib::API, :vcr do
  let(:capkey) { { 'HTTP_CAPKEY' => Settings.API_KEY } }
  let(:headers) { capkey.merge('CONTENT_TYPE' => 'application/json') }
  let(:publication) { create :publication }
  let(:author) { create :author }
  let(:test_title) { 'pathological' }
  let(:publication_with_test_title) { create :publication, title: test_title }
  let(:sourcelookup_path) { '/publications/sourcelookup' }
  let(:sourcelookup_by_title) do
    publication_with_test_title
    params = { format: 'json', title: test_title, maxrows: 2 }
    get sourcelookup_path, params: params, headers: capkey
    expect(response.status).to eq(200)
    JSON.parse(response.body)
  end

  before { allow(Settings.WOS).to receive(:enabled).and_return(true) }

  describe 'GET /publications/sourcelookup ' do
    it 'raises an error when title and doi are not sent' do
      expect do
        get sourcelookup_path, headers: capkey
      end.to raise_error ActionController::ParameterMissing
    end

    describe '?doi' do
      let(:doi_value) { '10.1016/j.mcn.2012.03.008' }
      let(:doi_identifier) do
        FactoryBot.create(:publication_identifier,
                           identifier_type: 'doi',
                           identifier_value: doi_value,
                           identifier_uri: "https://doi.org/#{doi_value}")
      end
      let(:result) do
        params = { format: 'json', doi: doi_value }
        get sourcelookup_path, params: params, headers: capkey
        expect(response.status).to eq(200)
        JSON.parse(response.body)
      end

      it 'returns one document ' do
        expect(result['metadata']['records']).to eq('1')
        expect(result['records'].first['wos_uid']).to eq('WOS:000305547700008')
      end

      it 'does not query provider if there is an existing publication with the doi' do
        doi_identifier.publication.save
        expect(result['metadata']).to include('records' => '1')
        record = result['records'].first
        expect(record['title']).to match(/Protein kinase C alpha/i)
        expect(record['provenance']).to eq 'wos'
      end
    end

    describe '?pmid' do
      it 'returns one document' do
        allow(Settings.WOS).to receive(:enabled).and_return(false)
        params = { format: 'json', pmid: '24196758' }
        get '/publications/sourcelookup', params: params, headers: capkey
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['metadata']).to include('records' => '1')
        record = result['records'].first
        expect(record).to include('mla_citation', 'chicago_citation')
        expect(record).to include('apa_citation' => /^Sittig, D. F./)
        expect(record['provenance']).to eq('pubmed')
      end
    end

    describe '?title=' do
      describe 'returns bibjson' do
        it 'with expected sections' do
          result = sourcelookup_by_title
          expect(result).to include('metadata', 'records')
          expect(result['metadata']).not_to be_empty
          expect(result['records']).not_to be_empty
        end
      end

      it 'with maxrows number of records' do
        params = { format: 'json', title: test_title, maxrows: 5 }
        get sourcelookup_path, params: params, headers: capkey
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['records'].length).to eq(5)
      end

      it 'does a title search' do
        expect(WebOfScience.queries).to receive(:user_query)
          .with('TI="lung cancer treatment"')
          .and_return(instance_double(WebOfScience::Retriever, next_batch: Array.new(20) { {} }))
        params = { format: 'json', title: 'lung cancer treatment' }
        get sourcelookup_path, params: params, headers: capkey
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['metadata']['records']).to eq('20')
      end

      it 'returns results that match the requested title' do
        result = sourcelookup_by_title
        expect(result).to include('records')
        expect(result['records']).not_to be_empty
        records = result['records']
        matches = records.count { |r| r['title'] =~ /#{test_title}/i }
        expect(matches).to eq(records.count) # ALL records match
      end

      it 'returns results that match the requested year' do
        year = 2015.to_s
        expect(WebOfScience.queries).to receive(:user_query)
          .with("TI=\"#{test_title}\" AND PY=2015")
          .and_return(instance_double(WebOfScience::Retriever, next_batch: ['year' => year]))
        params = { format: 'json', title: test_title, year: year }
        get sourcelookup_path, params: params, headers: capkey
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result).to include('records')
        expect(result['records']).not_to be_empty
        expect(result['records'].map { |r| r['year'] }).to all eq(year) # ALL records match
      end
    end

    # TODO: discriminate between sciencewire and local somehow?
    it 'returns results from sciencewire'
    it 'returns results from local pubs'
    it 'returns combined results from sciencewire and local pubs'
    # it 'returns combined results from sciencewire and local pubs' do
    #   skip
    #   publication_with_test_title
    #   result = sourcelookup_by_title
    #   expect(result).to include('records')
    #   # binding.pry
    # end
  end
end
