module ScienceWire
  module API
    ##
    # Class for SUL "Recommendation" requests for ScienceWire using
    # MatchedPublicationItemIdsForAuthor
    class MatchedPublicationItemIdsForAuthor
      attr_reader :client

      ##
      # @param [ScienceWire::Client] client
      def initialize(client:)
        @client = client
      end

      ##
      # @param [String] body
      def matched_publication_item_ids_for_author(body)
        ScienceWire::Request.new(
          client: client,
          request_method: :post,
          body: body,
          path: Settings.SCIENCEWIRE.RECOMMENDATION_PATH,
          timeout_period: 500
        ).perform
      end
    end
  end
end
