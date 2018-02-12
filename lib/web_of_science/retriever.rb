
module WebOfScience

  # Retrieve records from the Web of Science (or Web of Knowledge)
  # - expose retrieval API to fetch records in batches
  # - the "next_batch?" is like "next?"
  # - the "next_batch" is like "next"
  class Retriever
    include Enumerable

    attr_reader :records_found

    # @param [Symbol] operation SOAP operation like :search, :retrieve_by_id etc.
    # @param [Hash] message SOAP query message
    # @param [Integer] batch_size number of records to fetch by batch (MAX_RECORDS = 100)
    # @example
    #   WebOfScience::Retriever.new(:cited_references, message)
    def initialize(operation, message, batch_size = MAX_RECORDS)
      @batch = []
      @batch_iteration = 0
      @batch_size = batch_size
      @operation = operation
      @response_type = "#{operation}_response".to_sym
      @query = message
      @query_id = -99
      @records_found = -99
      @records_retrieved = 0
    end

    # @yield [WebOfScience::Record]
    def each
      next_batch.each { |rec| yield rec } while next_batch?
      reset
    end

    # @return [Boolean] are more records available?
    def next_batch?
      records_found < 0 || records_retrieved < records_found
    end

    # Retrieve the next batch of records (without merging).
    # @return [Array<WebOfScience::Record>]
    def next_batch
      next_batch? ? retrieve_batch : []
    end

    # Reset the batch retrieval to start again
    # @return [void]
    def reset
      @batch = []
      @batch_iteration = 0
      @query_id = -99
      @records_found = -99
      @records_retrieved = 0
    end

    private

      # this is the maximum number that can be returned in a single query by WoS
      MAX_RECORDS = 100

      attr_reader :batch
      attr_reader :batch_size
      attr_reader :operation # SOAP operations, like :search, :retrieve_by_id etc.
      attr_reader :query
      attr_reader :query_id
      attr_reader :response_type
      attr_reader :records_retrieved

      delegate :client, to: WebOfScience

      # Fetch the first batch of results.  The first query-response is special; it's the only
      # response that contains the entire query response metadata, with query_id and records_found.
      # @return [Array<WebOfScience::Record>]
      def batch_one
        response = client.search.call(operation, message: query)
        @batch = response_records(response, response_type)
        @records_found = response_return(response, response_type)[:records_found].to_i
        @records_retrieved = batch.count
        @query_id = response_return(response, response_type)[:query_id].to_i
        batch
      end

      # The retrieve operation is different from the first query, because it uses
      # a query_id and a :retrieve operation to retrieve additional records
      # @return [Array<WebOfScience::Record>]
      def retrieve_batch
        @batch_iteration += 1
        return batch_one if query_id < 0
        offset = (@batch_iteration * batch_size) + 1
        retrieve_message = {
          queryId: query_id,
          retrieveParameters: query[:retrieveParameters].merge(firstRecord: offset)
        }
        response = client.search.call(retrieve_operation, message: retrieve_message)
        @batch = response_records(response, "#{retrieve_operation}_response".to_sym)
        @records_retrieved += batch.count
        batch
      end

      # The retrieve operation is `:retrieve`, except for a :cited_references query
      # @return [Symbol] retrieve operation
      def retrieve_operation
        operation == :cited_references ? :cited_references_retrieve : :retrieve
      end

      ###################################################################
      # WoS SOAP Response Parsers

      # @param response [Savon::Response] a WoS SOAP response
      # @param response_type [Symbol] a WoS SOAP response type
      # @return [Hash] return data
      def response_return(response, response_type)
        response.body[response_type][:return]
      end

      # @param response [Savon::Response] a WoS SOAP response
      # @param response_type [Symbol] a WoS SOAP response type
      # @return [Array<WebOfScience::Record>]
      def response_records(response, response_type)
        WebOfScience::Records.new(records: response_return(response, response_type)[:records]).to_a
      end
  end
end
