# frozen_string_literal: true

require 'faraday'
require 'webmock'

module WebOfScience
  # WebOfScience WSDL files
  class WSDL
    WSDL_AUTH_FILE = Rails.root.join('spec/fixtures/wos_client/authenticate_wsdl.xml').freeze
    WSDL_SEARCH_FILE = Rails.root.join('spec/fixtures/wos_client/search_wsdl.xml').freeze

    WSDL_AUTH = 'http://search.webofknowledge.com/esti/wokmws/ws/WOKMWSAuthenticate?wsdl'
    WSDL_SEARCH = 'http://search.webofknowledge.com/esti/wokmws/ws/WokSearch?wsdl'

    class << self
      @@fetched = false

      def stub_auth_wsdl
        fetch
        WebMock.stub_request(:get, WSDL_AUTH)
               .to_return(status: 200, body: File.read(WSDL_AUTH_FILE))
      end

      def stub_search_wsdl
        fetch
        WebMock.stub_request(:get, WSDL_SEARCH)
               .to_return(status: 200, body: File.read(WSDL_SEARCH_FILE))
      end

      def fetch
        return if @@fetched

        response = Faraday.get(WSDL_AUTH)
        File.write(WSDL_AUTH_FILE, response.body) if response.success?
        response = Faraday.get(WSDL_SEARCH)
        File.write(WSDL_SEARCH_FILE, response.body) if response.success?
        @@fetched = true
      end
    end
  end
end
