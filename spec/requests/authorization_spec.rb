# frozen_string_literal: true

describe 'Authorization checks' do
  context 'for Rails controllers' do
    context 'when no CAPKEY provided' do
      it 'returns a 401' do
        get '/publications'
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'when incorrect CAPKEY provided' do
      it 'returns a 403' do
        get '/publications', headers: { 'CAPKEY' => 'not correct' }
        expect(response).to have_http_status :forbidden
      end
    end
  end

  context 'for authorship API' do
    context 'when no CAPKEY provided' do
      it 'returns a 401' do
        post '/authorship'
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'when incorrect CAPKEY provided' do
      it 'returns a 403' do
        post '/authorship', headers: { 'CAPKEY' => 'not correct' }
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
