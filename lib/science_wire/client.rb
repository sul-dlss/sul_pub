module ScienceWire
  ##
  # The configurable client and preferred API for interacting with the
  # ScienceWire library from within sul-pub.
  class Client
    include ScienceWire::API

    attr_accessor :license_id, :host
    delegate :matched_publication_item_ids_for_author, to: :matched_publication_item_ids_for_author_instance
    delegate :publication_items, to: :publication_items_instance
    delegate :send_publication_query, :retrieve_publication_query, to: :publication_query_instance

    ##
    # @param [String] license_id
    # @param [String] host
    def initialize(license_id:, host:)
      @license_id = license_id
      @host = host
    end

    private

      ##
      # @return [ScienceWire::API::MatchedPublicationItemIdsForAuthor]
      def matched_publication_item_ids_for_author_instance
        @matched_publication_item_ids_for_author ||= begin
          ScienceWire::API::MatchedPublicationItemIdsForAuthor.new(client: self)
        end
      end

      ##
      # @return [ScienceWire::API::PublicationItems]
      def publication_items_instance
        @publication_items_instance ||= begin
          ScienceWire::API::PublicationItems.new(client: self)
        end
      end

      ##
      # @return [ScienceWire::API::PublicationQuery]
      def publication_query_instance
        @publication_query_instance ||= begin
          ScienceWire::API::PublicationQuery.new(client: self)
        end
      end
  end
end
