module WebOfScience

  # Use author name-institution logic to find WOS publications for an Author
  class QueryAuthor

    def initialize(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      @names = Agent::AuthorName.new(
        author.last_name,
        author.first_name,
        Settings.HARVESTER.USE_MIDDLE_NAME ? author.middle_name : ''
      ).text_search_query
      @institution = Agent::AuthorInstitution.new(author.institution).normalize_name
      @options = options
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
      attr_reader :options

      # Use options to limit the symbolic time span for harvesting publications; this limit applies
      # to the dates publications are added or updated in WOS collections, not publication dates. To
      # quote the API documentation:
      #
      #     The symbolicTimeSpan element defines a range of load dates. The load date is the date when a record
      #     was added to a database. If symbolicTimeSpan is specified, the timeSpan parameter must be omitted.
      #     If timeSpan and symbolicTimeSpan are both omitted, then the maximum publication date time span
      #     will be inferred from the editions data.
      #
      #     - The documented values are strings: '1week', '2week', '4week' (prior to today)
      #     - the actual values it accepts are any value of "Nweek" for 1 < N < 53
      #
      # @return [Hash]
      def author_query
        params = queries.params_for_fields(empty_fields)
        params[:queryParameters][:userQuery] = "AU=(#{names}) AND AD=(#{institution})"
        if options[:symbolicTimeSpan]
          # to use symbolicTimeSpan, timeSpan must be omitted
          params[:queryParameters].delete(:timeSpan)
          params[:queryParameters][:symbolicTimeSpan] = options[:symbolicTimeSpan]
          params[:queryParameters][:order!] = [:databaseId, :userQuery, :symbolicTimeSpan, :queryLanguage] # according to WSDL
        end
        params
      end

      # Use Settings.WOS.ACCEPTED_DBS to define collections without any fields retrieved
      # @return [Array<Hash>]
      def empty_fields
        Settings.WOS.ACCEPTED_DBS.map { |db| { collectionName: db, fieldName: [''] } }
      end
  end
end
