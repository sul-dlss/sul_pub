module ScienceWire
  module API
    ##
    # Class for SUL "Publication Query" requests for ScienceWire
    class PublicationQuery
      attr_reader :client

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
          path: Settings.SCIENCEWIRE.PUBLICATION_QUERY_PATH
        ).perform
      end

      ##
      # @param [String] queryId
      def retrieve_publication_query(queryId)
        ScienceWire::Request.new(
          client: client,
          request_method: :get,
          path: "#{Settings.SCIENCEWIRE.PUBLICATION_QUERY_PATH.split(/\?/).first}/#{queryId}?format=xml&v=version/4&page=0&pageSize=2147483647"
        ).perform
      end
    end
  end
end
