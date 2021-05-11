# frozen_string_literal: true

describe 'Authorization checks' do
  context 'for Rails controllers' do
    context 'when no CAPKEY provided' do
      it 'returns a 401' do
        get '/publications'
        expect(response.status).to eq 401
      end
    end

    context 'when incorrect CAPKEY provided' do
      it 'returns a 403' do
        get '/publications', headers: { 'CAPKEY' => 'not correct' }
        expect(response.status).to eq 403
      end
    end
  end

  context 'for authorship API' do
    context 'when no CAPKEY provided' do
      it 'returns a 401' do
        post '/authorship'
        expect(response.status).to eq 401
      end
    end

    context 'when incorrect CAPKEY provided' do
      it 'returns a 403' do
        post '/authorship', headers: { 'CAPKEY' => 'not correct' }
        expect(response.status).to eq 403
      end
    end
  end
end
