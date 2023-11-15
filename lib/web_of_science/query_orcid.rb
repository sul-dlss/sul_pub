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

      queries.user_query_uids(orcid_query, query_params:).merged_uids
    end

    def valid?
      orcidid.present?
    end

    private

    delegate :queries, to: :WebOfScience

    attr_reader :orcidid, :options

    def query_params
      queries.user_query_options_to_params(options)
    end

    def orcid_query
      "AI=(\"#{Orcid.base_orcidid(orcidid)}\")"
    end
  end
end
