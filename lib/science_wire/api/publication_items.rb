module ScienceWire
  module API
    ##
    # Module of methods for SUL "Publication Query" requests for ScienceWire
    module PublicationItems
      ##
      # @param [String] ids
      def publication_items(ids)
        ScienceWire::Request.new(
          client: self,
          request_method: :get,
          path: Settings.SCIENCEWIRE.PUBLICATION_ITEMS_PATH + ids,
          timeout_period: 500
        ).perform
      end
    end
  end
end
