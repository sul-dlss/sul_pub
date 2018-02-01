
module WebOfScience

  # Queries on the Web of Science (or Web of Knowledge)
  class Queries

    # this is the maximum number that can be returned in a single query by WoS
    MAX_RECORDS = 100

    QUERY_LANGUAGE = 'en'.freeze

    # limit the start date when searching for publications, format: YYYY-MM-DD
    START_DATE = '1970-01-01'.freeze

    attr_reader :database

    # @param database [String] a WOS database identifier (default 'WOK')
    def initialize(database = 'WOK')
      @database = database
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Retriever]
    def cited_references(uid)
      raise(ArgumentError, 'uid must be a WOS-UID String') if uid.blank?
      options = [ { key: 'Hot', value: 'On' } ]
      message = base_uid_params.merge(uid: uid,
                                      retrieveParameters: retrieve_parameters(options: options))
      WebOfScience::Retriever.new(:cited_references, message)
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Retriever]
    def citing_articles(uid)
      raise(ArgumentError, 'uid must be a WOS-UID String') if uid.blank?
      message = base_uid_params.merge(uid: uid, timeSpan: time_span)
      WebOfScience::Retriever.new(:citing_articles, message)
    end

    # @param uid [String] a WOS UID
    # @return [WebOfScience::Retriever]
    def related_records(uid)
      raise(ArgumentError, 'uid must be a WOS-UID String') if uid.blank?
      # The 'WOS' database is the only option for this query
      message = base_uid_params.merge(uid: uid, databaseId: 'WOS', timeSpan: time_span)
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

    # @param name [String] a CSV name pattern: last_name, first_name [middle_name | middle initial]
    # @param institutions [Array<String>] a set of institutions the author belongs to
    # @return [WebOfScience::Retriever]
    def search_by_name(name, institutions = [])
      user_query = "AU=(#{name_query(name)})"
      user_query += " AND AD=(#{institutions.join(' OR ')})" unless institutions.empty?
      message = params_for_search(user_query)
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
