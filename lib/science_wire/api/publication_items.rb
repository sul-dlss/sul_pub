module ScienceWire
  module API
    ##
    # Class for SUL "Publication Query" requests for ScienceWire
    class PublicationItems
      attr_reader :client

      FORMATS = %w(xml json).freeze
      PATH = '/PublicationCatalog/PublicationItems'.freeze

      ##
      # @param [ScienceWire::Client] client
      def initialize(client:)
        @client = client
      end

      ##
      # @param [String] sw_ids - CSV PublicationItemId values (no whitespace)
      # @param [String] format - either 'xml' or 'json'
      def publication_items(sw_ids, format = 'xml')
        raise ArgumentError, 'format must be "xml" or "json"' unless FORMATS.include?(format)
        path = PATH + "?format=#{format}&publicationItemIDs=#{sw_ids}"
        ScienceWire::Request.new(
          client: client,
          request_method: :get,
          path: path,
          timeout_period: 500
        ).perform
      end
    end
  end
end
