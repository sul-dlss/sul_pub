module ScienceWire
  module API
    ##
    # Module of methods for SUL "Publication Query" requests for ScienceWire
    module PublicationQuery
      ##
      # @param [String] body
      def send_publication_query(body)
        ScienceWire::Request.new(
          client: self,
          request_method: :post,
          body: body,
          path: Settings.SCIENCEWIRE.PUBLICATION_QUERY_PATH
        ).perform
      end

      ##
      # @param [String] queryId
      def retrieve_publication_query(queryId)
        ScienceWire::Request.new(
          client: self,
          request_method: :get,
          path: "#{Settings.SCIENCEWIRE.PUBLICATION_QUERY_PATH.split(/\?/).first}/#{queryId}?format=xml&v=version/3&page=0&pageSize=2147483647"
        ).perform
      end
    end
  end
end
