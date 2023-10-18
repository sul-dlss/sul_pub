# frozen_string_literal: true

require 'clarivate/rest_client'

module Clarivate
  class RestLinksClient
    def self.working?
      wos_uids = %w[WOS:A1976BW18000001 WOS:A1972N549400003]
      links = new.links(wos_uids)
      raise 'Links client did not return the correct number of records' unless links.length == 2

      true
    end

    # Retrieve identifier fields for the record ids
    # @param [Array<String>] ids
    # @param [Array<String>] fields (defaults to ['doi', 'pmid'])
    # @return [Hash<String => Hash>]
    def links(ids, fields: %w[doi pmid])
      {}.tap do |links|
        ids.each_slice(100) do |ids_slice|
          links.merge!(LinksGet.new(ids_slice, fields, client).links)
        end
      end
    end

    private

    def client
      @client ||= Clarivate::RestClient.new
    end

    class LinksGet
      def initialize(ids, fields, client)
        @ids = ids
        @fields = fields
        @client = client
        raise ArgumentError, 'only 100 ids can be requested at a time' if ids.size > 100
        raise ArgumentError, 'ids must be prefixed with WOS:' unless ids_prefixed?
      end

      def links
        links_hash = records.to_h do |record|
          [record['UID'], identifiers_from(record)]
        end
        ids.each { |id| links_hash[id] ||= {} }
        links_hash
      end

      private

      attr_reader :ids, :fields, :client

      def records
        response_json.dig('Data', 'Records', 'records', 'REC')
      end

      def response_json
        client.json_get("/id/#{ids.join(',')}", params)
      end

      def ids_prefixed?
        ids.all? { |id| id.start_with?('WOS:') }
      end

      def params
        {
          databaseId: 'WOS',
          count: 100,
          firstRecord: 1
        }
      end

      def identifiers_from(record)
        identifiers = record.dig('dynamic_data', 'cluster_related', 'identifiers')
        return {} if identifiers.blank?

        identifiers['identifier']
          .select { |identifier| fields.include?(identifier['type']) }
          .to_h { |identifier| [identifier['type'], normalized_id(identifier['value'])] }
      end

      # remove unncessary PMID prefix from identifiers returned by the Links client
      def normalized_id(val)
        val.delete_prefix('MEDLINE:')
      end
    end
  end
end
