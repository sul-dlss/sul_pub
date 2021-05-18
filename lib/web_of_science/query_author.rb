# frozen_string_literal: true

module WebOfScience
  # Use author name-institution logic to find WOS publications for an Author
  # fetch the wos uids for the given author
  # e.g. WebOfScience::QueryAuthor.new(author).uids
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

    def valid?
      names.present?
    end

    private

    delegate :queries, to: :WebOfScience

    attr_reader :identities, :options

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
        end&.text_search_terms
      end.flatten.compact.uniq
    end

    def institutions
      identities.map { |ident| Agent::AuthorInstitution.new(ident.institution).normalize_name }.uniq
    end

    def author_query
      queries.construct_uid_query("AU=(#{quote_wrap(names).join(' OR ')}) AND AD=(#{quote_wrap(institutions).join(' OR ')})", options)
    end

    # @param [Array<String>] terms
    # @param [Array<String>] the same terms, minus any empties or duplicates, wrapped in double quotes
    def quote_wrap(terms)
      terms.reject(&:empty?).uniq.map { |x| "\"#{x.delete('"')}\"" }
    end
  end
end
