module WebOfScience

  # Use author name-institution logic to find WOS publications for an Author
  class QueryAuthor

    def initialize(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      @identities = [author].concat(author.author_identities.to_a) # query for alternates once, not multiple times
      @options = options
    end

    # Find all WOS-UIDs for an author
    # @return [Array<String>] WosUIDs
    # Implementation note: these records have a relatively small memory footprint, just UIDs
    def uids
      queries.search(author_query).merged_uids
    end

    private

      delegate :queries, to: :WebOfScience

      attr_reader :identities
      attr_reader :options

      def author
        identities.first
      end

      def names
        identities.map do |ident|
          if ident.first_name =~ /[a-zA-Z]+/
            Agent::AuthorName.new(
              ident.last_name,
              ident.first_name,
              Settings.HARVESTER.USE_MIDDLE_NAME ? ident.middle_name : ''
            )
          end.text_search_terms
        end.flatten.compact.uniq
      end

      def institutions
        identities.map { |ident| Agent::AuthorInstitution.new(ident.institution).normalize_name }.uniq
      end

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
      #     - the actual values it accepts are any value of "Nweek" for 1 <= N <= 52, or "Nyear" for 1 <= N <= 10
      #
      # @return [Hash]
      def author_query
        params = queries.params_for_fields(empty_fields)
        params[:queryParameters][:userQuery] = "AU=(#{quote_wrap(names).join(' OR ')}) AND AD=(#{quote_wrap(institutions).join(' OR ')})"
        if options[:symbolicTimeSpan]
          # to use symbolicTimeSpan, timeSpan must be omitted
          params[:queryParameters].delete(:timeSpan)
          params[:queryParameters][:symbolicTimeSpan] = options[:symbolicTimeSpan]
          params[:queryParameters][:order!] = [:databaseId, :userQuery, :symbolicTimeSpan, :queryLanguage] # according to WSDL
        end
        params
      end

      # @param [Array<String>] terms
      # @param [Array<String>] the same terms, minus any empties or duplicates, wrapped in double quotes
      def quote_wrap(terms)
        terms.reject(&:empty?).uniq.map { |x| "\"#{x.delete('"')}\"" }
      end

      # Use Settings.WOS.ACCEPTED_DBS to define collections without any fields retrieved
      # @return [Array<Hash>]
      def empty_fields
        Settings.WOS.ACCEPTED_DBS.map { |db| { collectionName: db, fieldName: [''] } }
      end
  end
end
