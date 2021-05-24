# frozen_string_literal: true

module WebOfScience
  # Use author orcid to find WOS publications for an Author
  # fetch the wos uids for the given author
  # e.g. WebOfScience::QueryOrcid.new(author).uids
  class QueryOrcid
    def initialize(author, options = {})
      @orcidid = author.orcidid
      @options = options
    end

    # Find all WOS-UIDs for an author
    # @return [Array<String>] WosUIDs
    # Implementation note: these records have a relatively small memory footprint, just UIDs
    def uids
      return [] unless valid?

      queries.search(orcid_query).merged_uids
    end

    def valid?
      orcidid.present?
    end

    private

    delegate :queries, to: :WebOfScience

    attr_reader :orcidid, :options

    def orcid_query
      queries.construct_uid_query("RID=(\"#{Orcid.base_orcidid(orcidid)}\")", options)
    end
  end
end
