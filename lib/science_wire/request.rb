module ScienceWire
  ##
  # Creates a connection to the external API, performs request, and returns the
  # response
  class Request
    attr_accessor :client
    attr_reader :timeout_period, :body, :path, :response, :request_method
    ##
    # @param [ScienceWire::Client] client
    # @param [Symbol] request_method
    # @param [String] body
    # @param [String] path
    # @param [Integer] timeout_period
    def initialize(client:, request_method:, body: '', path: '', timeout_period: 100)
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
        Faraday.new(url: base_url, request: {
          timeout: timeout_period
        }) do |faraday|
          faraday.request :retry, max: 3
          faraday.adapter Faraday.default_adapter
        end
      end

      ##
      # Sets additional request parameters
      # @return [Faraday::Response]
      def response
        connection.send(request_method) do |req|
          req.url path
          req.headers['LicenseID'] = client.licence_id
          req.headers['Host'] = client.host
          req.headers['Connection'] = 'Keep-Alive'
          req.headers['Expect'] = '100-continue'
          req.headers['Content-Type'] = 'text/xml'
          req.body = body
        end
      end

      ##
      # Defines the base_url for the request (protocol + uri + port)
      # @return [String]
      def base_url
        "https://#{Settings.SCIENCEWIRE.BASE_URI}:#{Settings.SCIENCEWIRE.PORT}"
      end
  end
end
