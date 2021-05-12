# frozen_string_literal: true

module Cap
  class Client
    # Fetch a single object from CAP server and test its response
    def self.working?
      response = new.get_auth_profile(4176)
      response.is_a?(Hash) && response['profileId'] == 4176
    end

    def get_batch_from_cap_api(page_count = 1, page_size = 1000, since = '')
      params = "?p=#{page_count}&ps=#{page_size}"
      params = "#{params}&since=#{since}" if since.present?
      api_request(params)
    end

    def get_auth_profile(cap_profile_id)
      params = "/#{cap_profile_id}"
      api_request(params)
    end

    private

    # Issue an API request and parse a JSON response
    # @return [Hash]
    def api_request(params)
      authenticate
      response = cap_client.get "#{API_PATH}#{params}"
      JSON.parse(response.body)
    rescue Faraday::TimeoutError => e
      NotificationManager.error(e, 'Timeout error during CAP-API request', self)
      raise
    rescue StandardError => e
      NotificationManager.error(e, "#{e.class.name} during CAP-API request", self)
      raise
    end

    # Authentication
    def authenticate
      cap_client.headers[:Authorization] = access_token
    end

    # @return [String] bearer access token
    def access_token
      @access_token = nil if @access_expiry.to_i < Time.zone.now.to_i
      @access_token ||= begin
        response = auth_client.get '?grant_type=client_credentials'
        raise 'Failed to authenticate' unless response.success?

        auth_data = JSON.parse(response.body)
        token = auth_data['access_token']
        @access_expiry = Time.now.to_i + auth_data['expires_in'].to_i
        "Bearer #{token}"
      end
    end
    ####################################################################################
    # CAP client connection settings
    #

    API_URI = "#{Settings.CAP.AUTHORSHIP_API_URI}:#{Settings.CAP.AUTHORSHIP_API_PORT}"
    API_PATH = Settings.CAP.AUTHORSHIP_API_PATH.freeze
    API_TIMEOUT_PERIOD = 500
    API_TIMEOUT_OPEN = 10
    API_TIMEOUT_RETRIES = 3

    AUTH_URI = "#{Settings.CAP.TOKEN_URI}#{Settings.CAP.TOKEN_PATH}"
    AUTH_CODE = Base64.strict_encode64("#{Settings.CAP.TOKEN_USER}:#{Settings.CAP.TOKEN_PASS}").freeze

    # CAP authentication client
    # @return [Faraday::Connection]
    def auth_client
      @auth_client ||= begin
        conn = connection(AUTH_URI)
        conn.headers[:Authorization] = "Basic #{AUTH_CODE}"
        conn
      end
    end

    # CAP API client
    # @return [Faraday::Connection]
    def cap_client
      @cap_client ||= connection(API_URI)
    end

    def connection(url)
      conn = Faraday.new(url) do |faraday|
        faraday.request :retry,
                        max: API_TIMEOUT_RETRIES,
                        interval: 0.8,
                        interval_randomness: 0.2,
                        backoff_factor: 2
        faraday.ssl.update(verify: true, verify_mode: OpenSSL::SSL::VERIFY_PEER)
        faraday.use Faraday::Response::RaiseError
        faraday.adapter :httpclient
      end
      connection_json(conn)
      connection_options(conn)
    end

    def connection_json(conn)
      json_content = 'application/json'
      conn.headers.update(accept: json_content, content_type: json_content)
      conn
    end

    def connection_options(conn)
      conn.options.timeout = API_TIMEOUT_PERIOD
      conn.options.open_timeout = API_TIMEOUT_OPEN
      conn
    end
  end
end
