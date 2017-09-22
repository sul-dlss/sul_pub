module ScienceWire
  ##
  # The configurable client and preferred API for interacting with the
  # ScienceWire library from within sul-pub.
  class Client
    include ScienceWire::API

    attr_accessor :license_id, :host
    delegate :matched_publication_item_ids_for_author,
             :matched_publication_item_ids_for_author_and_parse,
             to: :matched_publication_item_ids_for_author_instance
    delegate :publication_items, to: :publication_items_instance
    delegate :send_publication_query, :retrieve_publication_query, to: :publication_query_instance
    delegate :id_suggestions, to: :id_suggestions_instance

    # @param [String] license_id
    # @param [String] host
    def initialize(license_id:, host:)
      @license_id = license_id
      @host = host
    end

    private

      # @return [ScienceWire::IdSuggestions]
      def id_suggestions_instance
        @id_suggestions ||= ScienceWire::IdSuggestions.new(client: self)
      end

      # @return [ScienceWire::API::MatchedPublicationItemIdsForAuthor]
      def matched_publication_item_ids_for_author_instance
        @matched_publication_item_ids_for_author ||= ScienceWire::API::MatchedPublicationItemIdsForAuthor.new(client: self)
      end

      # @return [ScienceWire::API::PublicationItems]
      def publication_items_instance
        @publication_items_instance ||= ScienceWire::API::PublicationItems.new(client: self)
      end

      # @return [ScienceWire::API::PublicationQuery]
      def publication_query_instance
        @publication_query_instance ||= ScienceWire::API::PublicationQuery.new(client: self)
      end
  end
end
