# frozen_string_literal: true

describe 'Defaults' do
  describe 'GET home page for external API user health checks' do
    it 'returns a 200' do
      get '/'
      expect(response.status).to eq 200
    end
  end
end
