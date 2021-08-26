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
      get("/v3.0/#{Orcid.base_orcidid(orcidid)}/works")
    end

    # Fetch the details for a work
    def fetch_work(orcidid, put_code)
      get("/v3.0/#{Orcid.base_orcidid(orcidid)}/work/#{put_code}")
    end

    # Fetches the name for a user given an orcidid
    def fetch_name(orcidid)
      match = /[0-9xX]{4}-[0-9xX]{4}-[0-9xX]{4}-[0-9xX]{4}/.match(orcidid)
      raise 'invalid orcidid provided' unless match

      response = public_conn.get("/v3.0/#{match[0]&.upcase}/personal-details")
      case response.status
      when 200
        resp_json = JSON.parse(response.body)
        [resp_json.dig('name', 'given-names', 'value'),
         resp_json.dig('name', 'family-name', 'value')]
      else
        raise "ORCID.org API returned #{response.status} (#{response.body}) for: #{orcidid}"
      end
    end

    # Run a generalized search query against ORCID
    # see https://info.orcid.org/documentation/api-tutorials/api-tutorial-searching-the-orcid-registry
    def search(query)
      # this is the maximum number of rows ORCID allows in their response currently
      max_num_returned = 1000
      total_response = get("/v3.0/search/?q=#{query}&rows=#{max_num_returned}")
      num_results = total_response['num-found']

      return total_response if num_results <= max_num_returned

      num_pages = (num_results / max_num_returned.to_f).ceil

      # we already have page 1 of the results
      (1..num_pages - 1).each do |page_num|
        response = get("/v3.0/search/?q=#{query}&start=#{(page_num * max_num_returned) + 1}&rows=#{max_num_returned}")
        total_response['result'] += response['result']
      end

      total_response
    end

    # Add a new work for a researcher.
    # @param [string] ORCID ID for the researcher
    # @param [Hash] work in correct data structure for ORCID work
    # @param [string] access token
    # @return [string] put-code
    def add_work(orcidid, work, token)
      response = conn_with_token(token).post("/v3.0/#{Orcid.base_orcidid(orcidid)}/work",
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
        raise "ORCID.org API returned #{response.status} (#{response.body}) for: #{work.to_json}"
      end
    end

    # Delete a work
    # @param [string] ORCID ID for the researcher
    # @param [string] put-code
    # @param [string] access token
    # @return [boolean] true if delete succeeded
    def delete_work(orcidid, put_code, token)
      response = conn_with_token(token).delete("/v3.0/#{Orcid.base_orcidid(orcidid)}/work/#{put_code}")

      case response.status
      when 204
        true
      when 404
        false
      else
        raise "ORCID.org API returned #{response.status} when deleting #{put_code} for #{orcidid}"
      end
    end

    private

    def get(url)
      response = conn.get(url)
      raise "ORCID.org API returned #{response.status}" if response.status != 200

      JSON.parse(response.body).with_indifferent_access
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
    def public_conn
      conn = Faraday.new(url: Settings.ORCID.BASE_PUBLIC_URL) do |faraday|
        faraday.request :retry, max: 5,
                                interval: 0.5,
                                interval_randomness: 0.5,
                                backoff_factor: 2
        faraday.adapter :httpclient
      end
      conn.options.timeout = 500
      conn.options.open_timeout = 10
      conn.headers = headers
      conn
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
      conn.headers = headers
      conn.headers[:authorization] = "Bearer #{token}"
      conn
    end

    def headers
      {
        'Accept' => 'application/json',
        'User-Agent' => 'stanford-library-sul-pub'
      }
    end
  end
end
