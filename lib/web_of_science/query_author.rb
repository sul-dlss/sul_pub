module WebOfScience

  # Use author name-institution logic to find WOS publications for an Author
  class QueryAuthor

    def initialize(author)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      @names = Agent::AuthorName.new(
        author.last_name,
        author.first_name,
        Settings.HARVESTER.USE_MIDDLE_NAME ? author.middle_name : ''
      ).text_search_query
      @institution = Agent::AuthorInstitution.new(author.institution).normalize_name
    end

    # Find all WOS-UIDs for an author
    # @return [Array<String>] WosUIDs
    def uids
      # TODO: iterate on author identities also, or leave that to the consumer of this class?
      # Implementation note: these records have a relatively small memory footprint, just UIDs
      retriever = queries.search(author_query)
      retriever.merged_uids
    end

    private

      delegate :queries, to: :WebOfScience

      attr_reader :names
      attr_reader :institution

      # @return [Hash]
      def author_query
        params = queries.params_for_fields(empty_fields)
        params[:queryParameters][:userQuery] = "AU=(#{names}) AND AD=(#{institution})"
        params
      end

      def empty_fields
        Settings.WOS.ACCEPTED_DBS.map { |db| { collectionName: db, fieldName: [''] } }
      end

  end
end
