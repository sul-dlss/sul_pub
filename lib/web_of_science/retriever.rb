module WebOfScience
  # Retrieve records from the Web of Science (or Web of Knowledge)
  # - expose retrieval API to fetch records in batches
  # - the "next_batch?" is like "next?"
  # - the "next_batch" is like "next"
  class Retriever
    attr_reader :records_found, :records_retrieved

    # @param [Symbol] operation SOAP operation like :search, :retrieve_by_id etc.
    # @param [Hash] message SOAP query message
    # @param [Integer] batch_size number of records to fetch by batch (MAX_RECORDS = 100)
    # @example
    #   WebOfScience::Retriever.new(:cited_references, message)
    def initialize(operation, message, batch_size = MAX_RECORDS)
      @batch_iteration = 0
      @batch_size = batch_size
      @query = message
      @operation = operation
      @response_type = "#{operation}_response".to_sym
    end

    # @return [Boolean] all records retrieved?
    def records_retrieved?
      @batch_one.nil? ? false : records_retrieved == records_found
    end

    # Retrieve and merge all records
    # WARNING - this can exceed memory allocations
    # @return [WebOfScience::Records]
    def merged_records
      all_records = batch_one
      while next_batch?
        this_batch = next_batch
        all_records = all_records.merge_records(this_batch) unless this_batch.nil?
      end
      all_records
    end

    # Retrieve and collect all record UIDs
    # @return [Array<String>] WosUIDs
    def merged_uids
      uids = batch_one.uids
      uids += next_batch.uids while next_batch?
      uids
    end

    # @return [Boolean] are more records available?
    def next_batch?
      @batch_one.nil? || records_retrieved < records_found
    end

    # Retrieve the next batch of records (without merging).
    # @return [WebOfScience::Records, nil]
    def next_batch
      return batch_one if @batch_one.nil?
      return if records_retrieved?

      retrieve_batch
    end

    # Reset the batch retrieval to start again (after the first batch)
    # Never discard batch_one, it belongs to the query_id
    # @return [void]
    def reset
      @batch_iteration = 0
      @records_retrieved = batch_one.count
    end

    private

    # this is the maximum number that can be returned in a single query by WoS
    MAX_RECORDS = 100

    attr_reader :batch_size, :operation, :query, :query_id, :response_type # SOAP operations, like :search, :retrieve_by_id etc.

    delegate :client, to: WebOfScience

    # Fetch the first batch of results.  The first query-response is special; it's the only
    # response that contains the entire query response metadata, with query_id and records_found.
    # @return [WebOfScience::Records]
    def batch_one
      @batch_one ||= begin
        response = client.search.call(operation, message: query)
        records = response_records(response, response_type)
        @records_found = response_return(response, response_type)[:records_found].to_i
        @records_retrieved = records.count
        @query_id = response_return(response, response_type)[:query_id].to_i
        records
      end
    end

    # The retrieve operation is different from the first query, because it uses
    # a query_id and a :retrieve operation to retrieve additional records
    # @return [WebOfScience::Records]
    def retrieve_batch
      @batch_iteration += 1
      response = client.search.call(retrieve_operation, message: retrieve_message)
      records = response_records(response, "#{retrieve_operation}_response".to_sym)
      @records_retrieved += records.count
      records
    end

    # @return [Hash]
    def retrieve_message
      offset = (@batch_iteration * batch_size) + 1
      {
        queryId: query_id,
        retrieveParameters: query[:retrieveParameters].merge(firstRecord: offset)
      }
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
    # @return [WebOfScience::Records]
    def response_records(response, response_type)
      WebOfScience::Records.new(records: response_return(response, response_type)[:records])
    end
  end
end
