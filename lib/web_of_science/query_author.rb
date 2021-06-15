# frozen_string_literal: true

module WebOfScience
  # Search WoS for all publications for a given author, using both the name and ORCID queries, and then de-duping the UIDs
  # fetch the wos uids for the given author
  # e.g. WebOfScience::QueryAuthor.new(author).uids
  class QueryAuthor
    attr_reader :orcid_query, :name_query

    def initialize(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author

      @orcid_query = QueryOrcid.new(author, options)
      @name_query = QueryName.new(author, options)
    end

    # Find all WOS-UIDs for an author using both ORCID and Name queries, and then de-dupe
    # @return [Array<String>] WosUIDs
    # Implementation note: these records have a relatively small memory footprint, just UIDs
    def uids
      (orcid_query.uids + name_query.uids).uniq
    end

    # Indictes if we have a valid query for this author, only one needs to be ok to harvest
    def valid?
      orcid_query.valid? || name_query.valid?
    end
  end
end
