# frozen_string_literal: true

module WebOfScience
  # Retrieve records from the Web of Science (or Web of Knowledge)
  # - expose retrieval API to fetch records in batches
  # - the "next_batch?" is like "next?"
  # - the "next_batch" is like "next"
  class BaseRestRetriever
    # this is the maximum number that can be returned in a single query by WoS
    MAX_RECORDS = 100

    attr_reader :records_found, :records_retrieved, :query_id

    # @param [String] path of REST endpoint
    # @param [Hash] query parameters
    # @param [String] database ID to search (WOK by default)
    # @param [Integer] batch_size number of records to fetch by batch (MAX_RECORDS = 100)
    def initialize(path, params, database: 'WOK', batch_size: MAX_RECORDS)
      @path = path
      @params = params
      @database = database
      @batch_iteration = 0
      @batch_size = batch_size
    end

    # @return [Boolean] are more records available?
    def next_batch?
      @batch_one.nil? || records_retrieved < records_found
    end

    # Retrieve the next batch of records (without merging).
    # @return [WebOfScience::Records, nil]
    def next_batch
      return batch_one if @batch_one.blank?
      return if records_retrieved?

      retrieve_batch
    end

    private

    attr_reader :batch_size, :query, :path, :params, :database

    delegate :client, to: WebOfScience

    # @return [Boolean] all records retrieved?
    def records_retrieved?
      @batch_one.blank? ? false : records_retrieved == records_found
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

    # Fetch the first batch of results.  The first query-response is special; it's the only
    # response that contains the entire query response metadata, with query_id and records_found.
    # @return [WebOfScience::Records]
    def batch_one
      @batch_one ||= begin
        response = client.xml_get(path, merged_params)
        records = WebOfScience::Records.new(records: response.at('/xmlns:response/xmlns:map/xmlns:map[@name="Data"]/xmlns:val[@name="Records"]').text)
        @records_found = response.at('/xmlns:response/xmlns:map/xmlns:map[@name="QueryResult"]/xmlns:map/xmlns:val[@name="RecordsFound"]').text.to_i
        @records_retrieved = records.count
        @query_id = response.at('/xmlns:response/xmlns:map/xmlns:map[@name="QueryResult"]/xmlns:map/xmlns:val[@name="QueryID"]').text
        records
      end
    end

    # The retrieve operation is different from the first query, because it uses
    # a query_id and a :retrieve operation to retrieve additional records
    # @return [WebOfScience::Records]
    def retrieve_batch
      @batch_iteration += 1
      response = client.xml_get("/query/#{query_id}", merged_params)
      records = WebOfScience::Records.new(records: response.at('/xmlns:response/xmlns:map/xmlns:val[@name="Records"]').text)
      @records_retrieved += records.count
      records
    end

    def merged_params
      {
        count: batch_size,
        firstRecord: (@batch_iteration * batch_size) + 1,
        databaseId: database
      }.merge(params)
    end
  end
end
