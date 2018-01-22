# See also spec/api/sul_bib/sourcelookup_spec.rb

describe PublicationsController do
  let(:cap_id) { 'whatever' }

  it 'ensures authorization is checked' do
    expect(controller).to receive(:check_authorization)
    get :index, capProfileId: cap_id
  end

  describe 'GET index' do
    let(:author) { build :author }
    before { allow(controller).to receive(:check_authorization).and_return(true) }

    context 'with unknown capProfileId' do
      it 'returns a 404' do
        get :index, capProfileId: cap_id, format: 'json'
        expect(response.status).to eq 404
        expect(response.body).to include 'No such author'
      end
    end

    context 'with known capProfileId' do
      let(:json_response) { JSON.parse(response.body) }
      before { allow(Author).to receive(:find_by).with(cap_profile_id: cap_id).and_return(author) }

      it 'returns a structured response' do
        get :index, capProfileId: cap_id, format: 'json'
        expect(response.status).to eq 200
        expect(json_response).to match a_hash_including(
          'metadata' => a_hash_including('format' => 'BibJSON', 'page' => 1, 'per_page' => 1000, 'records' => '0'),
          'records' => []
        )
      end
    end
  end
end
