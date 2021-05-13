# frozen_string_literal: true

require 'oauth2'

module Orcid
  # Client for ORCID.org API.
  class Client
    # Fetch the works for a researcher.
    # Model for the response: https://pub.orcid.org/v3.0/#!/Development_Public_API_v3.0/viewWorksv3
    def fetch_works(orcidid)
      response = conn.get("/v3.0/#{orcidid[-19, 19]}/works")
      raise "ORCID.org API returned #{response.status}" if response.status != 200

      JSON.parse(response.body).with_indifferent_access
    end

    private

    def token
      client = OAuth2::Client.new(Settings.ORCID.CLIENT_ID, Settings.ORCID.CLIENT_SECRET, site: Settings.ORCID.BASE_AUTH_URL)
      token = client.client_credentials.get_token({ scope: '/read-public' })
      "Bearer #{token.token}"
    end

    # @return [Faraday::Connection]
    def conn
      @conn ||= begin
        conn = Faraday.new(url: Settings.ORCID.BASE_URL) do |faraday|
          faraday.request :retry, max: 3,
                                  interval: 0.5,
                                  interval_randomness: 0.5,
                                  backoff_factor: 2
          faraday.adapter :httpclient
        end
        conn.options.timeout = 500
        conn.options.open_timeout = 10
        conn.headers[:user_agent] = 'stanford-library-sul-pub'
        conn.headers[:accept] = 'application/json'
        conn.headers[:authorization] = token
        conn
      end
    end
  end
end
