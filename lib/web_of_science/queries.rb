# frozen_string_literal: true

module WebOfScience
  # Queries on the Web of Science (or Web of Knowledge)
  class Queries
    # this is the maximum number that can be returned in a single query by WoS
    MAX_RECORDS = 100

    # this is the _only_ value allowed by the WOS-API
    QUERY_LANGUAGE = 'en'

    attr_reader :database

    # @param database [String] a WOS database identifier (default 'WOK')
    def initialize(database = 'WOK')
      @database = database
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Retriever]
    def cited_references(uid)
      raise(ArgumentError, 'uid must be a WOS-UID String') if uid.blank?

      options = [{ key: 'Hot', value: 'On' }]
      message = base_uid_params.merge(uid: uid,
                                      retrieveParameters: retrieve_parameters(options: options))
      WebOfScience::Retriever.new(:cited_references, message)
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Retriever]
    def citing_articles(uid)
      raise(ArgumentError, 'uid must be a WOS-UID String') if uid.blank?

      message = base_uid_params.merge(uid: uid)
      WebOfScience::Retriever.new(:citing_articles, message)
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Retriever]
    def related_records(uid)
      raise(ArgumentError, 'uid must be a WOS-UID String') if uid.blank?

      # The 'WOS' database is the only option for this query
      message = base_uid_params.merge(uid: uid, databaseId: 'WOS')
      WebOfScience::Retriever.new(:related_records, message)
    end

    # @param uids [Array<String>] a list of WOS UIDs
    # @return [WebOfScience::Retriever]
    def retrieve_by_id(uids)
      raise(ArgumentError, 'uids must be an Enumerable of WOS-UID String') if uids.blank? || !uids.is_a?(Enumerable)

      message = base_uid_params.merge(uid: uids)
      WebOfScience::Retriever.new(:retrieve_by_id, message)
    end

    # Search for MEDLINE records matching PMIDs
    # @param pmids [Array<String>] a list of PMIDs
    # @return [WebOfScience::Retriever]
    def retrieve_by_pmid(pmids)
      raise(ArgumentError, 'pmids must be an Enumerable of PMID String') if pmids.blank? || !pmids.is_a?(Enumerable)

      uids = pmids.map { |pmid| "MEDLINE:#{pmid}" }
      retrieve_by_id(uids)
    end

    # @param doi [String] a digital object identifier (DOI)
    # @return [WebOfScience::Retriever]
    def search_by_doi(doi)
      raise(ArgumentError, 'doi must be a DOI String') if doi.blank?

      message = params_for_search("DO=#{doi}")
      message[:retrieveParameters][:count] = 50
      WebOfScience::Retriever.new(:search, message)
    end

    # @param message [Hash] search params (see WebOfScience::Queries#params_for_search)
    # @return [WebOfScience::Retriever]
    def search(message)
      WebOfScience::Retriever.new(:search, message)
    end

    # Convenience method, does the params_for_search expansion
    # @param message [Hash] Query string like 'TS=particle swarm AND PY=(2007 OR 2008)'
    # @return [WebOfScience::Retriever]
    def user_query(message)
      search(params_for_search(message))
    end

    # @param user_query [String] (defaults to '')
    # @return [Hash] search query parameters for full records
    def params_for_search(user_query = '')
      {
        queryParameters: {
          databaseId: database,
          userQuery: user_query,
          queryLanguage: QUERY_LANGUAGE
        },
        retrieveParameters: retrieve_parameters
      }
    end

    # Params to retrieve specific fields, not the full records; modify the retrieveParameters.
    # The `viewField` option can only be used without reference to the `FullRecord` namespace.
    # Also, the `viewField` must precede the `option` params in retrieveParameters.
    #
    # Using a `viewField` with an empty 'fieldName' results in returning only record-UIDs.
    #
    # @example
    # fields = [{ collectionName: "WOS", fieldName: [""] }, { collectionName: "MEDLINE", fieldName: [""] }]
    #
    # @param fields [Array<Hash>] as above
    # @return [Hash] search query parameters for specific fields
    def params_for_fields(fields)
      params = params_for_search
      params[:retrieveParameters] = {
        firstRecord: 1,
        count: 100,
        viewField: fields,
        option: [{ key: 'RecordIDs', value: 'On' }]
      }
      params
    end

    # Use options to limit the symbolic time span for harvesting publications; this limit applies
    # to the dates publications are added or updated in WOS collections, not publication dates. To
    # quote the API documentation:
    #
    #     The symbolicTimeSpan element defines a range of load dates. The load date is the date when a record
    #     was added to a database. If symbolicTimeSpan is specified, the timeSpan parameter must be omitted.
    #     If timeSpan and symbolicTimeSpan are both omitted, then the maximum publication date time span
    #     will be inferred from the editions data.
    #
    #     - The documented values are strings: '1week', '2week', '4week' (prior to today)
    #     - the actual values it accepts are any value of "Nweek" for 1 <= N <= 52, or "Nyear" for 1 <= N <= 10
    #
    # @param query [String] a query that will be sent to WoS
    # @param options [Hash] optional WoS query options to use with query
    # @return [Hash]
    def construct_uid_query(query_params, options = {})
      params = params_for_fields(empty_fields)
      params[:queryParameters][:userQuery] = query_params
      if options[:symbolicTimeSpan]
        # to use symbolicTimeSpan, timeSpan must be omitted
        params[:queryParameters].delete(:timeSpan)
        params[:queryParameters][:symbolicTimeSpan] = options[:symbolicTimeSpan]
        params[:queryParameters][:order!] = %i[databaseId userQuery symbolicTimeSpan queryLanguage] # according to WSDL
      end
      params
    end

    # Use Settings.WOS.ACCEPTED_DBS to define collections without any fields retrieved
    # @return [Array<Hash>]
    def empty_fields
      Settings.WOS.ACCEPTED_DBS.map { |db| { collectionName: db, fieldName: [''] } }
    end

    private

    ###################################################################
    # WoS Query Parameters

    # @return [Hash] UID query parameters
    def base_uid_params
      {
        databaseId: database,
        uid: [],
        queryLanguage: QUERY_LANGUAGE,
        retrieveParameters: retrieve_parameters
      }
    end

    # @param first_record [Integer] the record number offset (defaults to 1)
    # @param count [Integer] the number of records to retrieve (defaults to 100)
    # @return [Hash] retrieve parameters
    def retrieve_parameters(count: MAX_RECORDS, first_record: 1, options: retrieve_options)
      {
        firstRecord: first_record,
        count: count,
        option: options
      }
    end

    # @return [Array<Hash>] retrieve parameter options
    def retrieve_options
      [
        {
          key: 'RecordIDs',
          value: 'On'
        },
        {
          key: 'targetNamespace',
          value: 'http://scientific.thomsonreuters.com/schema/wok5.4/public/FullRecord'
        }
      ]
    end
  end
end
