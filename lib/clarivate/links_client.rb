module Clarivate
  # Links AMR (Article Match Retrieval) Service
  # @see http://ipscience-help.thomsonreuters.com/LAMRService/WebServicesOverviewGroup/overview.html Service documentation
  class LinksClient

    LINKS_HOST = 'https://ws.isiknowledge.com'.freeze
    LINKS_PATH = '/cps/xrpc'.freeze

    attr_reader :username, :password, :host

    # @param [String] username
    # @param [String] password
    # @param [String] host
    def initialize(username: nil, password: nil, host: LINKS_HOST)
      @host = host
      @username = username
      @password = password
      (@username, @password) = Base64.decode64(Settings.WOS.AUTH_CODE).split(':', 2) unless username
    end

    # Retrieve identifier 'fields' for the record 'ids'
    # @param [Array<String>] ids
    # @param [Array<String>] fields (defaults to ['ut', 'doi', 'pmid'])
    # @return [Hash<String => Hash>]
    def links(ids, fields = %w(ut doi pmid))
      ids.uniq!
      raise ArgumentError, '1-50 ids required' if ids.empty? || ids.count > 50
      raise ArgumentError, 'fields cannot be empty' if fields.empty?
      response = connection.post do |req|
        req.path = LINKS_PATH
        req.body = request_body(ids, fields)
      end
      response_parse(response)
    end

    private

      # @return [Faraday::Connection]
      def connection
        @connection ||= Faraday.new(url: host) do |faraday|
          faraday.use Faraday::Response::RaiseError
          faraday.adapter :httpclient
        end
      end

      # @return [ActionView::Base] used to render as though in an rails controller
      def renderer
        @renderer ||= ActionView::Base.new(ActionController::Base.view_paths, {})
      end

      # @param [Array<String>] fields
      # @return [String]
      def request_body(ids, fields)
        renderer.render(
          file: 'pages/clarivate_links.xml',
          layout: false,
          locals: {
            client: self,
            return_fields: fields,
            cites: ids
          }
        )
      end

      # @param response [Faraday::Response]
      def response_parse(response)
        ng = Nokogiri::XML(response.body) { |config| config.strict.noblanks }.remove_namespaces!
        pairs = ng.xpath('response/fn/map/map').map do |node|
          [node.attr('name').split('_', 2).last, vals_to_hash(node.children.xpath('val'))]
        end
        pairs.to_h
      end

      # @param [Nokogiri::XML::Nodeset] vals
      # @return [Hash<String => String>] namespace to value
      # Nodeset for [<val name="ut">UT</val>, <val name="doi">DOI</val>]
      # becomes { 'ut' => 'UT', 'doi' => 'DOI'}
      def vals_to_hash(vals)
        vals.map { |val| [val.attr('name'), val.text] }.to_h
      end
  end
end
