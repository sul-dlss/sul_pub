# frozen_string_literal: true

module WebOfScience
  # Retrieve records from the Web of Science user query endpoint
  class UserQueryRestRetriever < BaseRestRetriever
    # Model for the query parameters
    Query = Struct.new('UserQuery', :user_query, :publish_time_span, :load_time_span, :created_time_span, :modified_time_span, :database, :sort_field,
                       keyword_init: true) do
      # In most of the codebase, query parameters are passed around as options hashes.
      # The hashes may contain parameters that are for different services, so need to select only the ones for this service.
      # This creates a Query from an options hash.
      def self.from_options(options)
        new(**options.slice(*WebOfScience::UserQueryRestRetriever::Query.members))
      end
    end

    # @param query [WebOfScience::UserQueryRestRetriever::Query] parameters for the query
    # @param query_params [WebOfScience::UserQueryRestRetriever::Query] additional parameters for the query
    def initialize(query, query_params: nil, batch_size: WebOfScience::BaseRestRetriever::MAX_RECORDS)
      # Create query params from the Query and query_params Query.
      # The query_params Query is just a convenience for passing around additional parameters (like options but clearer).
      params = {
        usrQuery: query.user_query,
        publishTimeSpan: query.publish_time_span || query_params&.publish_time_span,
        loadTimeSpan: query.load_time_span || query_params&.load_time_span,
        createdTimeSpan: query.created_time_span || query_params&.created_time_span,
        modifiedTimeSpan: query.modified_time_span || query_params&.modified_time_span,
        databaseId: query.database || query_params&.database || 'WOK',
        sortField: query.sort_field || query_params&.sort_field
      }.compact
      super('/', params, batch_size:)
    end
  end
end
