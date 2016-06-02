module ScienceWire
  module API
    ##
    # Class for SUL "Publication Query" requests for ScienceWire
    class PublicationQuery
      attr_reader :client

      FORMATS = %w(xml json).freeze
      PATH = '/PublicationCatalog/PublicationQuery'.freeze

      ##
      # @param [ScienceWire::Client] client
      def initialize(client:)
        @client = client
      end

      ##
      # @param [String] body
      def send_publication_query(body)
        ScienceWire::Request.new(
          client: client,
          request_method: :post,
          body: body,
          path: "#{PATH}?format=xml"
        ).perform
      end

      ##
      # @param [Integer] queryId
      # @param [Integer] queryResultRows
      # @param [String] format - either 'xml' or 'json'
      def retrieve_publication_query(queryId, queryResultRows, format = 'xml')
        raise ArgumentError, 'format must be "xml" or "json"' unless FORMATS.include?(format)
        path = "#{PATH}/#{queryId}?format=#{format}&v=version/4&page=0&pageSize=#{queryResultRows}"
        ScienceWire::Request.new(
          client: client,
          request_method: :get,
          path: path
        ).perform
      end
    end
  end
end
