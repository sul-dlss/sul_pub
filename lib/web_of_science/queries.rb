# frozen_string_literal: true

module WebOfScience
  # Queries on the Web of Science (or Web of Knowledge)
  class Queries
    # @param uids [Array<String>] a list of WOS UIDs
    # @return [WebOfScience::IdQueryRestRetriever]
    def retrieve_by_id(uids)
      raise(ArgumentError, 'uids must be an Enumerable of WOS-UID String') if uids.blank? || !uids.is_a?(Enumerable)

      query = WebOfScience::IdQueryRestRetriever::Query.new(ids: uids)
      WebOfScience::IdQueryRestRetriever.new(query)
    end

    # Convenience method, does the params_for_search expansion
    # @param query [String] Query string like 'TS=particle swarm AND PY=(2007 OR 2008)'
    # @return [WebOfScience::UserQueryRestRetriever]
    def user_query(query_string, query_params: nil)
      query = WebOfScience::UserQueryRestRetriever::Query.new(user_query: query_string)
      WebOfScience::UserQueryRestRetriever.new(query, query_params:)
    end

    def user_query_options_to_params(options)
      WebOfScience::UserQueryRestRetriever::Query.from_options(options)
    end
  end
end
