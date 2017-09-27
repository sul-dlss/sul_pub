
# Queries on the Web of Science (or Web of Knowledge)
class WosQueries

  # this is the maximum number that can be returned in a single query by WoS
  MAX_RECORDS = 100

  QUERY_LANGUAGE = 'en'.freeze

  # limit the start date when searching for publications, format: YYYY-MM-DD
  START_DATE = '1970-01-01'.freeze

  attr_reader :wos_client

  # @param wos_client [WosClient] a Web Of Science client
  # @param database [String] a WOS database identifier (default 'WOK')
  def initialize(wos_client, database = 'WOK')
    @wos_client = wos_client
    @database = database
  end

  # @param uid [String] a WOS UID
  # @return [WosRecords]
  def cited_references(uid)
    cited_references_collator(uid)
  end

  # @param uid [String] a WOS UID
  # @return [WosRecords]
  def citing_articles(uid)
    citing_articles_collator(uid)
  end

  # @param uid [String] a WOS UID
  # @return [WosRecords]
  def related_records(uid)
    related_records_collator(uid)
  end

  # @param uids [Array<String>] a list of WOS UIDs
  # @return [WosRecords]
  def retrieve_by_id(uids)
    retrieve_by_id_collator(uids)
  end

  # @param name [String] a CSV name pattern: {last name}, {first_name} [{middle_name} | {middle initial}]
  # @return [WosRecords]
  def search_by_name(name)
    search_by_name_collator(name)
  end

  private

    ###################################################################
    # WoS Query Record Collators

    # @param uid [String] a WOS UID
    # @return [WosRecords]
    def cited_references_collator(uid)
      message = cited_references_params(uid)
      response = wos_client.search.call(:cited_references, message: message)
      retrieve_additional_records(response, :cited_references_response, :cited_references_retrieve)
    end

    # @param uid [String] a WOS UID
    # @return [WosRecords]
    def citing_articles_collator(uid)
      message = citing_articles_params(uid)
      response = wos_client.search.call(:citing_articles, message: message)
      retrieve_additional_records(response, :citing_articles_response)
    end

    # @param uid [String] a WOS UID
    # @return [WosRecords]
    def related_records_collator(uid)
      message = related_records_params(uid)
      response = wos_client.search.call(:related_records, message: message)
      retrieve_additional_records(response, :related_records_response)
    end

    # @param uids [Array<String>] a list of WOS UIDs
    # @return [WosRecords]
    def retrieve_by_id_collator(uids)
      message = retrieve_by_id_params(uids)
      response = wos_client.search.call(:retrieve_by_id, message: message)
      retrieve_additional_records(response, :retrieve_by_id_response)
    end

    # @return [WosRecords]
    def search_by_name_collator(name)
      message = search_by_name_params(name)
      response = wos_client.search.call(:search, message: message)
      retrieve_additional_records(response, :search_response)
    end

    # @param response [Savon::Response]
    # @param response_type [Symbol]
    # @param retrieve_operation [Symbol]
    # @return [WosRecords]
    def retrieve_additional_records(response, response_type, retrieve_operation = :retrieve)
      records = records(response, response_type)
      record_total = records_found(response, response_type)
      if record_total > MAX_RECORDS
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
    # @return [WosRecords]
    def records(response, response_type)
      WosRecords.new(records: response_return(response, response_type)[:records])
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
      name_query += " OR #{last_name} #{first_name[0]}#{middle_name[0]} OR #{last_name} #{first_name} #{middle_name[0]}" unless middle_name.blank?
      name_query
    end

    # Search authors from these institutions
    # @return [Array<String>] institution names
    def institutions
      ['Stanford University']
    end

    ###################################################################
    # WoS Query Parameters

    # @param uid [String] a WOS UID
    # @return [Hash] citedReferences parameters
    def cited_references_params(uid)
      retrieve_options = [ { key: 'Hot', value: 'On' } ]
      {
        databaseId: @database,
        uid: uid,
        queryLanguage: QUERY_LANGUAGE,
        retrieveParameters: retrieve_parameters(options: retrieve_options)
      }
    end

    # @param uid [String] a WOS UID
    # @return [Hash] citingArticles parameters
    def citing_articles_params(uid)
      {
        databaseId: @database,
        uid: uid,
        timeSpan: time_span,
        queryLanguage: QUERY_LANGUAGE,
        retrieveParameters: retrieve_parameters
      }
    end

    # @param uid [String] a WOS UID
    # @return [Hash] relatedRecords parameters
    def related_records_params(uid)
      # The 'WOS' database is the only option for this query
      {
        databaseId: 'WOS',
        uid: uid,
        timeSpan: time_span,
        queryLanguage: QUERY_LANGUAGE,
        retrieveParameters: retrieve_parameters
      }
    end

    # @param uids [Array<String>] a list of WOS UIDs
    # @return [Hash] retrieveById parameters
    def retrieve_by_id_params(uids)
      {
        databaseId: @database,
        uid: uids,
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
    def search_params(user_query)
      {
        queryParameters: {
          databaseId: @database,
          userQuery: user_query,
          timeSpan: time_span,
          queryLanguage: QUERY_LANGUAGE
        },
        retrieveParameters: retrieve_parameters
      }
    end

    # @param name [String] a CSV name pattern: {last name}, {first_name} [{middle_name} | {middle initial}]
    # @return [Hash] search query parameters
    def search_by_name_params(name)
      user_query = "AU=(#{name_query(name)}) AND AD=(#{institutions.join(' OR ')})"
      search_params(user_query)
    end

    # @return [Hash] time span dates
    def time_span
      {
        begin: START_DATE,
        end: Time.zone.now.strftime('%Y-%m-%d')
      }
    end
end
