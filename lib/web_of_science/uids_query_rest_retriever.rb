# frozen_string_literal: true

module WebOfScience
  # Retrieve just a list of UIDs from the Web of Science recordids endpoint
  class UidsQueryRestRetriever < UserQueryRestRetriever
    # @param query [WebOfScience::UserQueryRestRetriever::Query] parameters for the query
    # @param query_params [WebOfScience::UserQueryRestRetriever::Query] additional parameters for the query
    def initialize(query, query_params: nil, batch_size: WebOfScience::BaseRestRetriever::MAX_RECORDS)
      @query_string = query.user_query
      @query_params = query_params
      super
    end

    # Retrieve and collect all record UIDs
    # @return [Array<String>] WosUIDs
    def merged_uids
      uids = batch_one
      uids += next_batch while next_batch?
      uids
    end

    private

    attr_reader :query_string, :query_params

    # Fetch the first batch of results.  The first query-response is special; it's first issues a
    # batch size 0 for the query, which returns only the number of records and query_id.
    # We can then fetch the first set of WOS_UIDs
    # @return [Array<String>] WOS_UIDs
    def batch_one
      @batch_one ||= begin
        @records_retrieved = 0
        response = WebOfScience.queries.user_query(query_string, query_params:, batch_size: 0)
        response.next_batch

        @records_found = response.records_found
        @query_id = response.query_id

        @records_found == 0 ? [] : retrieve_batch # no results, return empty array right away, otherwise fetch a batch
      end
    end

    # The retrieve operation fetches more results from the WOS_UIDs fetch path
    # @return [Array<String>] WOS_UIDs
    def retrieve_batch
      records = client.json_get("/recordids/#{query_id}", merged_params)
      @records_retrieved += records.count
      @batch_iteration += 1
      records
    end
  end
end
