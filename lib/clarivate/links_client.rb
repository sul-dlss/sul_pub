# frozen_string_literal: true

require 'faraday/httpclient'

module Clarivate
  # Links AMR (Article Match Retrieval) Service
  # @see http://ipscience-help.thomsonreuters.com/LAMRService/WebServicesOverviewGroup/overview.html Service documentation
  class LinksClient
    LINKS_HOST = 'https://ws.isiknowledge.com'
    LINKS_PATH = '/cps/xrpc'
    ALL_FIELDS = %w[ut doi pmid title isbn issn issue vol year tpages sourceURL timesCited citingArticlesURL
                    relatedRecordsURL].freeze

    attr_reader :username, :password, :host

    def self.working?
      wos_uids = %w[WOS:A1976BW18000001 WOS:A1972N549400003]
      links = new.links(wos_uids)
      raise 'Links AMR client did not return the correct number of records' unless links.is_a?(Hash) && links.keys.count == 2

      true
    end

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
    def links(ids, fields: %w[doi pmid])
      raise ArgumentError, 'ids must be Enumerable' unless ids.is_a? Enumerable
      raise ArgumentError, 'fields cannot be empty' if fields.blank?

      ids.each_slice(50).inject({}) do |links, slice_ids|
        links.merge request_batch(slice_ids, fields)
      end
    end

    private

    # @return [Faraday::Connection]
    def connection
      @connection ||= Faraday.new(url: host) do |faraday|
        faraday.use Faraday::Response::RaiseError
        faraday.adapter :httpclient
      end
    end

    # @param [Array<String>] ids
    # @param [Array<String>] fields
    def request_batch(ids, fields)
      response = connection.post do |req|
        req.path = LINKS_PATH
        req.body = request_body(ids, fields)
      end
      response_parse(response)
    end

    # @param [Array<String>] ids
    # @param [Array<String>] fields
    # @return [String]
    def request_body(ids, fields)
      ApplicationController.render(
        formats: [:xml],
        template: 'requests/clarivate_links',
        layout: false,
        locals: {
          client: self,
          return_fields: fields,
          cites: ids
        }
      )
    end

    # @param response [Faraday::Response]
    # @return [Hash<String => Hash>]
    def response_parse(response)
      ng = Nokogiri::XML(response.body) { |config| config.strict.noblanks }.remove_namespaces!
      ng.xpath('response/fn/map/map').to_h { |node| response_map_parse(node) }
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
      return {} if vals.empty? || vals.first.text == 'No Result Found'

      vals.to_h { |val| [val.attr('name'), val.text] }
    end
  end
end
