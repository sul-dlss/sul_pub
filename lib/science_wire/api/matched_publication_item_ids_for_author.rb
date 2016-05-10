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

      ##
      # @param [String] body
      # @return [Array]
      def matched_publication_item_ids_for_author_and_parse(body)
        parse(matched_publication_item_ids_for_author(body))
      end

      ##
      # @param [String] response_body
      # @return [Array<Integer>]
      def parse(response_body)
        Nokogiri::XML(response_body)
                .xpath('/ArrayOfItemMatchResult/ItemMatchResult/PublicationItemID')
                .map { |item| item.text.to_i }
      end
    end
  end
end
