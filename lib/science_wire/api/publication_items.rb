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
      def publication_items(ids)
        ScienceWire::Request.new(
          client: client,
          request_method: :get,
          path: Settings.SCIENCEWIRE.PUBLICATION_ITEMS_PATH + ids,
          timeout_period: 500
        ).perform
      end
    end
  end
end
