
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
      retrieve_options = [ { key: 'Hot', value: 'On' } ]
      message = base_uid_params.merge(uid: uid,
                                      retrieveParameters: retrieve_parameters(options: retrieve_options))
      retrieve_records(:cited_references, message)
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Records]
    def citing_articles(uid)
      message = base_uid_params.merge(uid: uid, timeSpan: time_span)
      retrieve_records(:citing_articles, message)
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Records]
    def related_records(uid)
      # The 'WOS' database is the only option for this query
      message = base_uid_params.merge(uid: uid, databaseId: 'WOS', timeSpan: time_span)
      retrieve_records(:related_records, message)
    end

    # @param uids [Array<String>] a list of WOS UIDs
    # @return [WebOfScience::Records]
    def retrieve_by_id(uids)
      message = base_uid_params.merge(uid: uids)
      retrieve_records(:retrieve_by_id, message)
    end

    # @param user_query [String] a custom user query
    # @param message [Hash] optional search params (defaults to search_params)
    # @return [WebOfScience::Records]
    def search(user_query, message = search_params)
      message[:queryParameters][:userQuery] = user_query
      retrieve_records(:search, message)
    end

    # @param doi [String] a digital object identifier (DOI)
    # @return [WebOfScience::Records]
    def search_by_doi(doi)
      message = search_params("DO=#{doi}")
      message[:retrieveParameters][:count] = 10
      response = wos_client.search.call(:search, message: message)
      records = records(response, :search_response)
      # Return a unique DOI match or nothing, because the WoS API does partial string matching
      # on the `DO` field.  When the result set is only one record, it's likely to be a good match; but
      # otherwise the results could be nonsense.
      return records if records.count == 1
      WebOfScience::Records.new(records: '<records/>')
    end

    # @param name [String] a CSV name pattern: last_name, first_name [middle_name | middle initial]
    # @param institutions [Array<String>] a set of institutions the author belongs to
    # @return [WebOfScience::Records]
    def search_by_name(name, institutions = [])
      user_query = "AU=(#{name_query(name)})"
      user_query += " AND AD=(#{institutions.join(' OR ')})" unless institutions.empty?
      message = search_params(user_query)
      retrieve_records(:search, message)
    end

    private

      ###################################################################
      # WoS Query Record Collators

      def retrieve_records(operation, message)
        response = wos_client.search.call(operation, message: message)
        retrieve_additional_records(response, "#{operation}_response".to_sym)
      end

      # @param response [Savon::Response]
      # @param response_type [Symbol]
      # @return [WebOfScience::Records]
      def retrieve_additional_records(response, response_type)
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
            message = {
              queryId: query_id,
              retrieveParameters: retrieve_parameters(first_record: first_record)
            }
            response_i = wos_client.search.call(retrieve_operation, message: message)
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

      # @param user_query [String]
      # @return [Hash] search query parameters
      def search_params(user_query = '')
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

      # @return [Hash] time span dates
      def time_span
        {
          begin: START_DATE,
          end: Time.zone.now.strftime('%Y-%m-%d')
        }
      end
  end
end
