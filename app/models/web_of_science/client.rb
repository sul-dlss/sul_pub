module WebOfScience
  class Client
    attr_reader :host

    # @param [String] host
    # @note license_id not used in this version of API
    def initialize(host: 'http://search.webofknowledge.com')
      @host = host
    end

    def connection
      @conn ||= Faraday.new(:url => @host) do |f|
        f.adapter :net_http_persistent
        f.use Faraday::Response::RaiseError
      end
    end

    # @param [String] auth_key base64-encoded username:password
    # @return [String] Session ID, if successful
    def authenticate(auth_key = Settings.web_of_science.auth_key)
      raise ArgumentError, 'required: pass auth_key or set Settings.web_of_science.auth_key' unless auth_key
      auth = connection.post do |req|
        req.url '/esti/wokmws/ws/WOKMWSAuthenticate'
        req.headers['Content-Type'] = 'application/xml'
        req.headers['Authorization'] = "Basic #{auth_key}"
        req.body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:auth="http://auth.cxf.wokmws.thomsonreuters.com"><soapenv:Header/><soapenv:Body><auth:authenticate/></soapenv:Body></soapenv:Envelope>'
      end
      auth_xml_doc = Nokogiri::XML(auth.body).remove_namespaces!
      auth_xml_doc.xpath('//authenticateResponse//return')[0].content
    end

    # 6 Methods were exposed by ScienceWire::Client, of which we have to worry about only 5:
    # matched_publication_item_ids_for_author  **NOT called by consumers**
    # matched_publication_item_ids_for_author_and_parse
    # publication_items
    # send_publication_query
    # retrieve_publication_query
    # id_suggestions

    # @param [String] body request body XML
    # @return [Array<Integer>] identifiers
    def pub_ids_for_author(body)
      response = connection.send(:post) do |req|
        req.url '/PublicationCatalog/MatchedPublicationItemIdsForAuthor?format=xml' # need new path
        req.headers['Content-Type'] = 'text/xml'
        req.body = body
      end
      Nokogiri::XML(response)
        .xpath('/ArrayOfItemMatchResult/ItemMatchResult/PublicationItemID') # parse differently
        .map { |item| item.text.to_i }
    end

    alias_method :matched_publication_item_ids_for_author_and_parse, :pub_ids_for_author

    # @param [String] ids CSV PublicationItemId values (no whitespace)
    # @param [String] format desired response format, 'xml' or 'json'
    # @return [String] response body matching requested format
    def publication_items(ids, format = 'xml')
      raise ArgumentError, 'format must be "xml" or "json"' unless %w(xml json).include?(format)
      # previously had timeout_period: 500
      response = connection.send(:get) do |req|
        req.url "/PublicationCatalog/PublicationItems?format=#{format}&publicationItemIDs=#{ids}", # need new path
        req.headers['Content-Type'] = 'text/xml'
        req.body = body
      end
      response.body
    end

    # @param [String] body request body
    # @return [String] response body matching requested format
    def send_publication_query(body)
      response = connection.send(:post) do |req|
        req.url '/PublicationCatalog/PublicationQuery?format=xml' # need new path
        req.headers['Content-Type'] = 'text/xml'
        req.body = body
      end
      response.body
    end

    # @param [Integer] queryId
    # @param [Integer] queryResultRows
    # @param [String] format desired response format, 'xml' or 'json'
    # @return [String] response body matching requested format
    def retrieve_publication_query(queryId, queryResultRows, format = 'xml')
      raise ArgumentError, 'format must be "xml" or "json"' unless %w(xml json).include?(format)
      response = connection.send(:get) do |req|
        req.url "/PublicationCatalog/PublicationQuery/#{queryId}?format=#{format}&v=version/4&page=0&pageSize=#{queryResultRows}" # need new path
        req.headers['Content-Type'] = 'text/xml'
        req.body = body
      end
      response.body
    end

    # @param [ScienceWire::AuthorAttributes] attributes
    # @return [Array<Integer>]
    # @todo Replace ScienceWire::Query::Suggestion? Or maybe not?
    def id_suggestions(attributes)
      pub_ids_for_author(ScienceWire::Query::Suggestion.new(attributes, 'Journal Document')) +
        pub_ids_for_author(ScienceWire::Query::Suggestion.new(attributes, 'Conference Proceeding Document'))
    end
  end
end
