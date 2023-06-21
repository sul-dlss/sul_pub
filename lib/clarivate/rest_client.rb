# frozen_string_literal: true

module Clarivate
  class RestClient
    URL = 'https://wos-api.clarivate.com'
    API_PATH = '/api/wos'

    def json_get(path, params = {})
      resp = conn.get(API_PATH + path, params, headers('application/json'))
      JSON.parse(resp.body)
    end

    def xml_get(path, params = {})
      resp = conn.get(API_PATH + path, params, headers('application/xml'))
      Nokogiri::XML(resp.body)
    end

    private

    def conn
      @conn ||= Faraday.new(url: URL) do |faraday|
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
        faraday.request :retry, max: 2, interval: 1.25, retry_statuses: [429]
      end
    end

    def headers(accept)
      {
        'Accept' => accept,
        'X-ApiKey' => Settings.WOS.API_KEY
      }
    end
  end
end
