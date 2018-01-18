
module WebOfScience

  # Queries on the Web of Science (or Web of Knowledge)
  class Queries

    # this is the maximum number that can be returned in a single query by WoS
    MAX_RECORDS = 100

    QUERY_LANGUAGE = 'en'.freeze

    # limit the start date when searching for publications, format: YYYY-MM-DD
    START_DATE = '1970-01-01'.freeze

    attr_reader :wos_client
    attr_reader :database

    # Fetch a single publication and parse and ensure we have a correct response.
    # We check in steps that the response is XML and it includes the correct content.
    def self.working?
      uids = %w(WOS:A1976BW18000001 WOS:A1972N549400003)
      response = new.retrieve_by_id(uids)
      raise 'WebOfScience::Queries has no records' unless response.is_a?(WebOfScience::Records) && response.count > 0
      raise 'WebOfScience::Queries did not parse records' unless response.first.is_a?(WebOfScience::Record)
      true
    end

    # @param wos_client [WebOfScience::Client] a Web Of Science client
    # @param database [String] a WOS database identifier (default 'WOK')
    def initialize(wos_client = WebOfScience.client, database = 'WOK')
      @wos_client = wos_client
      @database = database
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Records]
    def cited_references(uid)
      return empty_records if uid.blank?
      retrieve_options = [ { key: 'Hot', value: 'On' } ]
      message = base_uid_params.merge(uid: uid,
                                      retrieveParameters: retrieve_parameters(options: retrieve_options))
      retrieve_records(:cited_references, message)
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Records]
    def citing_articles(uid)
      return empty_records if uid.blank?
      message = base_uid_params.merge(uid: uid, timeSpan: time_span)
      retrieve_records(:citing_articles, message)
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Records]
    def related_records(uid)
      return empty_records if uid.blank?
      # The 'WOS' database is the only option for this query
      message = base_uid_params.merge(uid: uid, databaseId: 'WOS', timeSpan: time_span)
      retrieve_records(:related_records, message)
    end

    # @param uids [Array<String>] a list of WOS UIDs
    # @return [WebOfScience::Records]
    def retrieve_by_id(uids)
      return empty_records if uids.blank?
      message = base_uid_params.merge(uid: uids)
      retrieve_records(:retrieve_by_id, message)
    end

    # Search for MEDLINE records matching PMIDs
    # @param pmids [Array<String>] a list of PMIDs
    # @return [WebOfScience::Records]
    def retrieve_by_pmid(pmids)
      return empty_records if pmids.blank?
      uids = pmids.map { |pmid| "MEDLINE:#{pmid}" }
      retrieve_by_id(uids)
    end

    # @param doi [String] a digital object identifier (DOI)
    # @return [WebOfScience::Records]
    def search_by_doi(doi)
      return empty_records if doi.blank?
      message = params_for_search("DO=#{doi}")
      message[:retrieveParameters][:count] = 10
      response = wos_client.search.call(:search, message: message)
      records = records(response, :search_response)
      # Return a unique DOI match or nothing, because the WoS API does partial string matching
      # on the `DO` field.  When the result set is only one record, it's likely to be a good match; but
      # otherwise the results could be nonsense.
      return records if records.count == 1
      empty_records
    end

    # @param name [String] a CSV name pattern: last_name, first_name [middle_name | middle initial]
    # @param institutions [Array<String>] a set of institutions the author belongs to
    # @return [WebOfScience::Records]
    def search_by_name(name, institutions = [])
      user_query = "AU=(#{name_query(name)})"
      user_query += " AND AD=(#{institutions.join(' OR ')})" unless institutions.empty?
      message = params_for_search(user_query)
      retrieve_records(:search, message)
    end

    # @param message [Hash] search params (see WebOfScience::Queries#params_for_search)
    # @return [WebOfScience::Records]
    def search(message)
      retrieve_records(:search, message)
    end

    # Convenience method, does the params_for_search expansion
    # @param message [Hash] Query string like 'TS=particle swarm AND PY=(2007 OR 2008)'
    # @return [WebOfScience::Records]
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
          timeSpan: time_span,
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

    private

      ###################################################################
      # WoS Query Record Collators

      # An empty set of records
      # @return [WebOfScience::Records]
      def empty_records
        WebOfScience::Records.new(records: '<records/>')
      end

      def retrieve_records(operation, message)
        response = wos_client.search.call(operation, message: message)
        retrieve_additional_records(message, response, "#{operation}_response".to_sym)
      end

      # @param message [Hash] search params
      # @param response [Savon::Response]
      # @param response_type [Symbol]
      # @return [WebOfScience::Records]
      def retrieve_additional_records(message, response, response_type)
        records = records(response, response_type)
        record_total = records_found(response, response_type)
        if record_total > MAX_RECORDS
          retrieve_operation = :retrieve
          retrieve_operation = :cited_references_retrieve if response_type == :cited_references_response
          query_id = query_id(response, response_type)
          # How many iterations to go?  We've already got MAX_RECORDS
          iterations = record_total / MAX_RECORDS
          iterations -= 1 if (record_total % MAX_RECORDS).zero?
          [*1..iterations].each do |i|
            first_record = (MAX_RECORDS * i) + 1
            retrieve_message = {
              queryId: query_id,
              retrieveParameters: message[:retrieveParameters].merge(firstRecord: first_record)
            }
            response_i = wos_client.search.call(retrieve_operation, message: retrieve_message)
            records_i = records(response_i, "#{retrieve_operation}_response".to_sym)
            records = records.merge_records records_i
          end
        end
        records
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
      # @return [Integer]
      def query_id(response, response_type)
        response_return(response, response_type)[:query_id].to_i
      end

      # @param response [Savon::Response] a WoS SOAP response
      # @param response_type [Symbol] a WoS SOAP response type
      # @return [Integer]
      def records_found(response, response_type)
        response_return(response, response_type)[:records_found].to_i
      end

      # @param response [Savon::Response] a WoS SOAP response
      # @param response_type [Symbol] a WoS SOAP response type
      # @return [WebOfScience::Records]
      def records(response, response_type)
        WebOfScience::Records.new(records: response_return(response, response_type)[:records])
      end

      ###################################################################
      # Search User Query Helpers

      # Constructs a WoS name query
      # @param name [String] a CSV name pattern: {last name}, {first_name} [{middle_name} | {middle initial}]
      def name_query(name)
        split_name = name.split(',')
        last_name = split_name[0]
        first_middle_name = split_name[1]
        first_name = first_middle_name.split(' ')[0]
        middle_name = first_middle_name.split(' ')[1]
        name_query = "#{last_name} #{first_name} OR #{last_name} #{first_name[0]}"
        name_query += " OR #{last_name} #{first_name[0]}#{middle_name[0]} OR #{last_name} #{first_name} #{middle_name[0]}" if middle_name.present?
        name_query
      end

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

      # @return [Hash] time span dates
      def time_span
        {
          begin: START_DATE,
          end: Time.zone.now.strftime('%Y-%m-%d')
        }
      end
  end
end
