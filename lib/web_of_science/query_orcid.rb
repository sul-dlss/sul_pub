# frozen_string_literal: true

module WebOfScience
  # Use author orcid to find WOS publications for an Author
  # fetch the wos uids for the given author
  # e.g. WebOfScience::QueryOrcid.new(author).uids
  class QueryOrcid
    def initialize(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author

      @orcid = author.orcidid
      @options = options
    end

    # Find all WOS-UIDs for an author
    # @return [Array<String>] WosUIDs
    # Implementation note: these records have a relatively small memory footprint, just UIDs
    def uids
      queries.search(orcid_query).merged_uids
    end

    def valid?
      orcidid.present?
    end

    private

    delegate :queries, to: :WebOfScience

    attr_reader :orcid, :options

    def orcid_query
      queries.construct_uid_query("RID=(\"#{orcid.gsub('orcid.org/', '')}\")", options)
    end
  end
end
