module ScienceWire
  ##
  # Creates a connection to the external API, performs request, and returns the
  # response
  class Request
    attr_accessor :client
    attr_reader :timeout_period, :body, :path, :request_method
    ##
    # @param [ScienceWire::Client] client
    # @param [Symbol] request_method
    # @param [String] body
    # @param [String] path
    # @param [Integer] timeout_period
    def initialize(client:, request_method:, body: '', path: '', timeout_period: 300)
      @client = client
      @request_method = request_method
      @body = body
      @path = path
      @timeout_period = timeout_period
    end

    ##
    # @return [String]
    def perform
      response.body
    end

    private

      ##
      # Sets initial connection parameters
      # @return [Faraday::Connection]
      def connection
        @connection ||= begin
          conn = Faraday.new(url: Settings.SCIENCEWIRE.BASE_URI) do |faraday|
            faraday.use Faraday::Response::RaiseError
            faraday.request :retry, max: 2,
              interval: 0.5,
              interval_randomness: 0.5,
              backoff_factor: 2
            faraday.adapter :httpclient
          end
          conn.options.timeout = timeout_period
          conn.options.open_timeout = 10
          conn
        end
      end

      ##
      # Sets additional request parameters
      # @return [Faraday::Response]
      def response
        connection.send(request_method) do |req|
          req.url path
          req.headers['LicenseID'] = client.license_id
          req.headers['Host'] = client.host
          req.headers['Connection'] = 'Keep-Alive'
          req.headers['Expect'] = '100-continue'
          req.headers['Content-Type'] = 'text/xml'
          req.body = body
        end
      end

  end
end
