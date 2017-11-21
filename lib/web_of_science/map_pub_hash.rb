module WebOfScience

  # Map WOS record data into the SUL PubHash data
  class MapPubHash < Mapper

    private

      attr_reader :pub

      # Map WOS record data into the SUL PubHash data
      # @return [Hash]
      def mapper
        @pub || begin
          @pub = {}
          pub_hash_abstract
          pub_hash_agents
          pub_hash_citation
          pub_hash_doctypes
          pub_hash_identifiers
          pub
        end
      end

      # publication abstract
      def pub_hash_abstract
        pub.update rec.abstract_mapper.pub_hash
      end

      # publication agents
      def pub_hash_agents
        pub.update WebOfScience::MapNames.new(rec).pub_hash
        pub.update rec.publisher.pub_hash
      end

      # publication citation details
      def pub_hash_citation
        pub.update WebOfScience::MapCitation.new(rec).pub_hash
      end

      # publication document types and categories
      def pub_hash_doctypes
        types = [rec.doctypes, rec.pub_info['pubtype']].flatten.compact
        pub[:documenttypes_sw] = types
        pub[:documentcategory_sw] = rec.pub_info['pubtype']
        pub[:type] = case rec.pub_info['pubtype']
                     when /conference/i
                       Settings.sul_doc_types.inproceedings
                     else
                       Settings.sul_doc_types.article
                     end
      end

      # publication identifiers
      def pub_hash_identifiers
        pub[:provenance] = Settings.wos_source
        pub[:doi] = rec.doi if rec.doi.present?
        pub[:eissn] = rec.eissn if rec.eissn.present?
        pub[:issn] = rec.issn if rec.issn.present?
        pub[:pmid] = rec.pmid if rec.pmid.present?
        pub[:wos_uid] = rec.uid
        pub[:wos_item_id] = rec.wos_item_id if rec.wos_item_id.present?
        pub[:identifier] = rec.identifiers.pub_hash
      end

  end
end
