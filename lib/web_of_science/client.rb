# frozen_string_literal: true

require 'savon'

module WebOfScience
  # A Web of Science (or Web of Knowledge) client
  # It uses the WSDL service definitions from WOS
  # See also:
  # https://clarivate.com/products/web-of-science/data-integration/
  # http://ipscience-help.thomsonreuters.com/wosWebServicesExpanded/WebServicesExpandedOverviewGroup/Introduction.html
  # It uses the savon gem for SOAP, see http://savonrb.com/version2/client.html
  class Client
    API_VERSION = '3.0' # Based on USER GUIDE July 7, 2015
    AUTH_WSDL = 'http://search.webofknowledge.com/esti/wokmws/ws/WOKMWSAuthenticate?wsdl'
    SEARCH_WSDL = 'http://search.webofknowledge.com/esti/wokmws/ws/WokSearch?wsdl'

    API_SESSION_QUERY_LIMIT = 2000

    def initialize(auth_code, log_level = Settings.WOS.LOG_LEVEL.to_sym)
      @auth_code = auth_code
      @log_level = log_level
      @session_queries = 0
    end

    # A client for the authorization endpoint, using WSDL
    # @return [Savon::Client]
    def auth
      @auth ||= Savon.client(
        wsdl: AUTH_WSDL,
        headers: { 'Authorization' => "Basic #{@auth_code}", 'SOAPAction' => [''] },
        env_namespace: :soapenv,
        logger: logger,
        log: true,
        log_level: @log_level,
        pretty_print_xml: true
      )
    end

    # Calls authenticate on the authentication endpoint
    # @return [Savon::Response]
    def authenticate
      auth.call(:authenticate)
    end

    # A client for the search endpoint, using WSDL
    # @return [Savon::Client]
    def search
      check_throttle_limits
      @search ||= Savon.client(
        wsdl: SEARCH_WSDL,
        headers: { 'Cookie' => "SID=\"#{session_id}\"", 'SOAPAction' => '' },
        env_namespace: :soapenv,
        logger: logger,
        log: true,
        log_level: @log_level,
        pretty_print_xml: true
      )
    end

    # Authenticates the session and returns the SID value
    # @return [String] a session ID
    def session_id
      @session_id ||= begin
        response = authenticate
        response.body[:authenticate_response][:return]
      end
    end

    # Calls close_session on the authentication endpoint
    # Resets the session_id and the search client
    # @return [void]
    def session_close
      begin
        auth.globals[:headers]['Cookie'] = "SID=\"#{session_id}\""
        auth.call(:close_session)
      rescue Savon::SOAPFault => e
        # Savon::SOAPFault: (soap:Server) No matches returned for SessionID
        logger.warn(e.inspect)
      end
      session_reset
    end

    def logger
      @logger ||= Logger.new('log/web_of_science_client.log')
    end

    private

    attr_reader :session_queries

    def check_throttle_limits
      @session_queries += 1
      session_close if session_queries > API_SESSION_QUERY_LIMIT
    end

    def session_reset
      @auth = nil
      @search = nil
      @session_id = nil
      @session_queries = 0
    end
  end
end
