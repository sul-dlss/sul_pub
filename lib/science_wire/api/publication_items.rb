module ScienceWire
  module API
    ##
    # Class for SUL "Publication Query" requests for ScienceWire
    class PublicationItems
      attr_reader :client

      ##
      # @param [ScienceWire::Client] client
      def initialize(client:)
        @client = client
      end

      ##
      # @param [String] ids
      def publication_items(ids, format = 'xml')
        path = Settings.SCIENCEWIRE.PUBLICATION_ITEMS_PATH
        path.gsub!('format=xml', 'format=json') if format == 'json'
        ScienceWire::Request.new(
          client: client,
          request_method: :get,
          path: path + ids,
          timeout_period: 500
        ).perform
      end
    end
  end
end
