module WebOfScience
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
    # @param [Array<String>] fields (defaults to ['doi', 'pmid'])
    # @return [Hash<String => Hash>]
    def links(ids, fields: %w(doi pmid))
      raise ArgumentError, '1-50 ids required' unless valid_identifier_list?(ids)
      raise ArgumentError, 'fields cannot be empty' if fields.blank?
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
        @renderer ||= begin
          lib_path = Rails.root.join('lib', 'web_of_science')
          view_path = ActionView::PathSet.new([lib_path])
          ActionView::Base.new(view_path, {})
        end
      end

      # @param [Array<String>] fields
      # @return [String]
      def request_body(ids, fields)
        renderer.render(
          file: 'links_request.xml',
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
        ng.xpath('response/fn/map/map').map { |node| response_map_parse(node) }.to_h
      end

      # @param node [Nokogiri::XML::Node] map node
      # @return [Array<String, Hash>]
      def response_map_parse(node)
        [response_cite_to_id(node), response_vals_to_hash(node.children.xpath('val'))]
      end

      # Extract the 'cite_{id}' from the cite node (in the name attribute)
      # @param node [Nokogiri::XML::Node] cite node
      # @return [String]
      def response_cite_to_id(node)
        node.attr('name').split('_', 2).last
      end

      # Nodeset for [<val name="ut">UT</val>, <val name="doi">DOI</val>]
      # becomes { 'ut' => 'UT', 'doi' => 'DOI'}
      # @param [Nokogiri::XML::Nodeset] vals
      # @return [Hash<String => String>] namespace to value
      def response_vals_to_hash(vals)
        return {} if vals.first.text == 'No Result Found'
        vals.map { |val| [val.attr('name'), val.text] }.to_h
      end

      # Validate the `ids` is an Enumerable and contains between 1-50 elements
      # @param [Enumerable] ids
      # @return [Boolean]
      def valid_identifier_list?(ids)
        return false unless ids.is_a? Enumerable
        ids.count.between?(1, 50)
      end

  end
end
