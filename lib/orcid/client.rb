# frozen_string_literal: true

require 'oauth2'

module Orcid
  # Client for ORCID.org API.
  class Client
    # Fetch the works for a researcher.
    # Model for the response: https://pub.orcid.org/v3.0/#!/Development_Public_API_v3.0/viewWorksv3
    # @param [string] ORCID ID for the researcher
    # @return [Hash]
    def fetch_works(orcidid)
      response = conn.get("/v3.0/#{base_orcidid(orcidid)}/works")
      raise "ORCID.org API returned #{response.status}" if response.status != 200

      JSON.parse(response.body).with_indifferent_access
    end

    # Add a new work for a researcher.
    # @param [string] ORCID ID for the researcher
    # @param [Hash] work in correct data structure for ORCID work
    # @param [string] access token
    # @return [string] put-code
    def add_work(orcidid, work, token)
      response = conn_with_token(token).post("/v3.0/#{base_orcidid(orcidid)}/work",
                                             work.to_json,
                                             'Content-Type' => 'application/json')

      case response.status
      when 201
        response['Location'].match(%r{work/(\d+)})[1]
      when 409
        match = response.body.match(/put-code (\d+)\./)
        raise 'ORCID.org API returned a 409, but could not find put-code' unless match

        match[1]
      else
        raise "ORCID.org API returned #{response.status}"
      end
    end

    private

    def base_orcidid(orcidid)
      orcidid[-19, 19]
    end

    def client_token
      client = OAuth2::Client.new(Settings.ORCID.CLIENT_ID, Settings.ORCID.CLIENT_SECRET, site: Settings.ORCID.BASE_AUTH_URL)
      token = client.client_credentials.get_token({ scope: '/read-public' })
      token.token
    end

    # @return [Faraday::Connection]
    def conn
      @conn ||= conn_with_token(client_token)
    end

    # @return [Faraday::Connection]
    def conn_with_token(token)
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
      conn.headers[:authorization] = "Bearer #{token}"
      conn
    end
  end
end
