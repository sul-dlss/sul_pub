# frozen_string_literal: true

module WebOfScience
  # Retrieve records from the Web of Science id endpoint
  class IdQueryRestRetriever < BaseRestRetriever
    # Model for the query parameters
    Query = Struct.new('IdQuery', :ids, :database, :sort_field, keyword_init: true)

    # @param query [WebOfScience::IdQueryRestRetriever::Query] parameters for the query
    def initialize(query, batch_size: WebOfScience::BaseRestRetriever::MAX_RECORDS)
      # Ids are provided in the path
      path = "/id/#{Array(query.ids).join(',')}"
      # Create query params from the Query
      params = {
        databaseId: query.database || 'WOK',
        sortField: query.sort_field
      }.compact

      super(path, params, batch_size:)
    end
  end
end
