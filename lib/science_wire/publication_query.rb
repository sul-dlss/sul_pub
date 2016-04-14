module ScienceWire
  ##
  # Module of methods for SUL "Publication Query" requests for ScienceWire
  module PublicationQuery
    ##
    # @param [String] body
    def publication_query(body)
      ScienceWire::Request.new(
        client: self,
        request_method: :post,
        body: body,
        path: Settings.SCIENCEWIRE.PUBLICATION_QUERY_PATH
      ).perform
    end
  end
end
