# frozen_string_literal: true

describe 'Defaults' do
  describe 'GET home page for external API user health checks' do
    it 'returns a 200' do
      get '/'
      expect(response).to have_http_status :ok
    end
  end
end
