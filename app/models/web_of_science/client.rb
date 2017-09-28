module WebOfScience
  class Client
    attr_reader :host

    # @param [String] host
    # @note license_id not used in this version of API
    def initialize(host: 'http://search.webofknowledge.com')
      @host = host
    end

    def logger
      @logger ||= ::Logger.new(STDOUT)
    end

    def connection
      @conn ||= Faraday.new(:url => @host) do |f|
        f.adapter :net_http_persistent
        f.response :logger, logger, :bodies => true # debugging on for now
        f.use Faraday::Response::RaiseError
      end
    end

    # just a means of rendering layout/template
    # @return [ApplicationController] cached controller for calling render_to_string on
    def controller
      @controller ||= ApplicationController.new
    end

    # @param [String] template
    # @param [Hash] assigns key and value assignments to pass to the template
    # @return [String] the rendered document
    # @example render('web_of_science/search', search_params)
    def render(template, assigns = {})
      controller.render_to_string(
        layout: 'wos_soap',
        template: template,
        locals: assigns # key becomes `assigns:` in rails 5
      )
    end

    # @param [String] auth_key base64-encoded username:password
    # @return [String] Session ID, if successful
    # @note Unfortunately, search.webofknowledge.com returns status 500 (w/ stack trace) for bad Authorization string.
    # Therefore, we cannot distinguish between actual server internal errors and failed auth.
    def authenticate(auth_key = Settings.web_of_science.auth_key)
      raise ArgumentError, 'required: pass auth_key or set Settings.web_of_science.auth_key' unless auth_key
      auth = connection.post do |req|
        req.url '/esti/wokmws/ws/WOKMWSAuthenticate'
        req.headers['Content-Type'] = 'application/xml'
        req.headers['Authorization'] = "Basic #{auth_key}"
        req.body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:auth="http://auth.cxf.wokmws.thomsonreuters.com"><soapenv:Header/><soapenv:Body><auth:authenticate/></soapenv:Body></soapenv:Envelope>'
      end
      auth_xml_doc = Nokogiri::XML(auth.body).remove_namespaces!
      element = auth_xml_doc.xpath('//authenticateResponse//return')
      raise "Failed to parse response response #{auth}\n#{auth_xml_doc}" unless element && element[0]
      element[0].content
    end

    def session_id
      @session_id ||= authenticate
    end

    # 6 Methods were exposed by ScienceWire::Client, of which we have to worry about only 5:
    # matched_publication_item_ids_for_author  **NOT called by consumers**
    # matched_publication_item_ids_for_author_and_parse (a terrible name)
    # publication_items
    # send_publication_query
    # retrieve_publication_query
    # id_suggestions

    # @param [Symbol] request_method
    # @param [String] path
    # @param [String] body
    # @param [Integer] timeout_period
    # @yield [Faraday::Request] the prepared request object for further manipulation before sending
    # @return [String] response body
    def request(request_method: :get, path: '', body: '', timeout_period: 300)
      response = connection.public_send(request_method) do |req|
        req.url path
        req.headers['Host'] = host
        req.headers['Connection'] = 'Keep-Alive'
        req.headers['Content-Type'] = 'text/xml'
        req.headers['Cookie'] = "SID=\"#{session_id}\""
        req.body = body
        yield req if block_given?
      end
      return response.body if response.success?
      @session_id = nil unless response.status = '200' # ideally we target session expiry more specifically
    end

    # @param [String] body request body XML
    # @return [Array<Integer>] identifiers
    def pub_ids_for_author(body)
      response_body = request(
        request_method: :post,
        path: '/PublicationCatalog/MatchedPublicationItemIdsForAuthor', # need new path
        body: body
      )
      Nokogiri::XML(response_body)
        .xpath('/ArrayOfItemMatchResult/ItemMatchResult/PublicationItemID') # parse differently
        .map { |item| item.text.to_i }
    end

    alias_method :matched_publication_item_ids_for_author_and_parse, :pub_ids_for_author

    # @param [Array<String>] ids PublicationItemId values (no whitespace)
    # @return [String] response body matching requested format
    def publication_items(ids)
      # previously had timeout_period: 500
      request(
        path: "/PublicationCatalog/PublicationItems?publicationItemIDs=#{ids}", # retreiveById?
        body: render('web_of_science/retrieve_by_id', :@uids => ids)
      )
    end

    # @param [String] body XML request body
    # @return [String] response body matching requested format
    def send_publication_query(body)
      request(
        request_method: :post,
        path: '/PublicationCatalog/PublicationQuery', # search?
        body: body
      )
    end

    # @param [Integer] queryId
    # @param [Integer] queryResultRows
    # @return [String] response body matching requested format
    def retrieve_publication_query(queryId, queryResultRows = 100)
      raise ArgumentError, 'queryResultRows must be an Integer <= 100' if queryResultRows > 100
      request(
        path: "/PublicationCatalog/PublicationQuery/#{queryId}?format=#{format}&v=version/4&page=0&pageSize=#{queryResultRows}", # search?
      )
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
