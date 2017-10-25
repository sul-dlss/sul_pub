module Clarivate
  # Links AMR (Article Match Retrieval) Service
  # @see http://ipscience-help.thomsonreuters.com/LAMRService/WebServicesOverviewGroup/overview.html Service documentation
  class LinksClient
    attr_reader :username, :password, :host

    # @param [String] username
    # @param [String] password
    # @param [String] host
    def initialize(username: nil, password: nil, host: 'https://ws.isiknowledge.com')
      @host = host
      @username = username
      @password = password
      (@username, @password) = Base64.decode64(Settings.WOS.AUTH_CODE).split(':', 2) unless username
    end

    # limited to 50 ids
    # @param [Array<String>] ids
    # @return [Hash<String => Hash>]
    def links(ids)
      raise ArgumentError, "1-50 ids required" unless ids.present? && ids.count <= 50
      response = connection.post do |req|
        req.path = '/cps/xrpc'
        req.body = request_body(ids.uniq)
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

      # @return [String]
      def request_body(ids)
        renderer.render(
          file: 'pages/clarivate_links.xml',
          layout: false,
          locals: {
            client: self,
            return_fields: %w(ut doi pmid),
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
      # @return [Hash<Symbol => String>] namespace to value
      # Nodeset for [<val name="ut">UT value</val>, <val name="doi">DOI</val>]
      # becomes { ut: 'UT value', doi: 'DOI'}
      def vals_to_hash(vals)
        vals.map { |val| [val.attr("name").downcase.to_sym, val.text.strip] }.to_h
      end
  end
end
