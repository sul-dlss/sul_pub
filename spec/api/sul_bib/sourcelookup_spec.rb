require 'spec_helper'

describe SulBib::API, :vcr do
  let(:capkey) { { 'HTTP_CAPKEY' => Settings.API_KEY } }
  let(:headers) { capkey.merge({ 'CONTENT_TYPE' => 'application/json' }) }
  let(:publication) { create :publication }
  let(:author) { create :author }
  let(:test_title) {'pathological'}
  let(:publication_with_test_title) { create :publication, title: test_title }
  let(:sourcelookup_path) {'/publications/sourcelookup'}
  let(:sourcelookup_by_title) {
    publication_with_test_title
    params = { format: 'json', title: test_title, maxrows: 2 }
    get sourcelookup_path, params, capkey
    expect(response.status).to eq(200)
    JSON.parse(response.body)
  }
  let(:test_doi) {'10.1016/j.mcn.2012.03.008'}
  let(:sourcelookup_by_doi) {
    params = { format: 'json', doi: test_doi }
    get sourcelookup_path, params, capkey
    expect(response.status).to eq(200)
    JSON.parse(response.body)
  }
  let(:valid_json_for_post) {
    {
      title: 'some title',
      year: 1938,
      author: [
        {
          name: 'jackson joe'
        }
      ],
      authorship: [
        {
          sul_author_id: author.id,
          status: 'denied',
          visibility: 'public',
          featured: true
        }
      ]
    }.to_json
  }

  describe 'GET /publications/sourcelookup ' do

    it 'raises an error when title and doi are not sent' do
      expect do
        get sourcelookup_path, {}, capkey
      end.to raise_error ActionController::ParameterMissing
    end

    describe '?doi' do
      it 'returns one document ' do
        result = sourcelookup_by_doi
        expect(result['metadata']['records']).to eq('1')
        expect(result['records'].first['sw_id']).to eq('60830932')
      end

      it 'does not query sciencewire if there is an existing publication with the doi' do
        publication.pub_hash = {
          identifier: [
            {
              type: 'doi',
              id: test_doi,
              url: "http://dx.doi.org/#{test_doi}"
            }
          ]
        }
        publication.sync_identifiers_in_pub_hash_to_db
        result = sourcelookup_by_doi
        expect(result['metadata']).to include('records')
        expect(result['metadata']['records']).to eq('1')
        record = result['records'].first
        expect(record['title']).to match(/Protein kinase C alpha/i)
        expect(record['provenance']).to match(/sciencewire/)
      end
    end

    describe '?pmid' do
      it 'returns one document' do
        path = '/publications/sourcelookup'
        params = { format: 'json', pmid: '24196758' }
        get path, params, capkey
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['metadata']).to include('records')
        expect(result['metadata']['records']).to eq('1')
        record = result['records'].first
        expect(record).to include('provenance')
        expect(record['provenance']).to eq 'sciencewire'
        expect(record).to include('apa_citation')
        expect(record).to include('mla_citation')
        expect(record).to include('chicago_citation')
        expect(record['apa_citation']).to match(/^Sittig, D. F./)
      end
    end

    describe '?title=' do

      describe 'returns bibjson' do
        it 'with metadata section' do
          result = sourcelookup_by_title
          expect(result).to include('metadata')
          expect(result['metadata']).not_to be_empty
        end
        it 'with records section' do
          result = sourcelookup_by_title
          expect(result).to include('records')
          expect(result['records']).not_to be_empty
        end
      end

      it 'with maxrows number of records' do
        params = { format: 'json', title: test_title, maxrows: 5 }
        get sourcelookup_path, params, capkey
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['records'].length).to eq(5)
      end

      it 'does a sciencewire title search' do
        title = 'lung cancer treatment'
        params = { format: 'json', title: title }
        get sourcelookup_path, params, capkey
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['metadata']['records']).to eq('20')
      end

      it 'returns results that match the requested title' do
        result = sourcelookup_by_title
        expect(result).to include('records')
        expect(result['records']).not_to be_empty
        records = result['records']
        matches = records.count {|r| r['title'] =~ /#{test_title}/i }
        expect(matches).to eq(records.count) # ALL records match
      end

      it 'returns results that match the requested year' do
        year = 2015.to_s
        params = { format: 'json', title: test_title, year: year}
        get sourcelookup_path, params, capkey
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result).to include('records')
        expect(result['records']).not_to be_empty
        records = result['records']
        matches = records.count {|r| r['year'] == year }
        expect(matches).to eq(records.count) # ALL records match
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
