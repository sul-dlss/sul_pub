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
        # TODO
        # binding.pry
        # pub[:abstract_restricted] = abstracts #yes there might be multiple abstracts
      end

      # publication agents
      def pub_hash_agents
        # - use names, with role, to include 'author' and other roles, possibly 'editor' also
        # - the PubHash class has methods to separate them when creating citations
        pub[:author] = pub_hash_names
        pub[:authorcount] = rec.authors.count
        pub.update rec.publisher.pub_hash
      end

      # publication citation details
      def pub_hash_citation
        pub.update WebOfScience::MapCitation.new(rec).pub_hash
      end

      # publication document types and categories
      def pub_hash_doctypes
        # binding.pry

        # Notes for book reviews that are journal articles
        #
        # publication_id: 331355,
        #   identifier_type: "WoSItemID",
        #   identifier_value: "000244272600114",
        #   identifier_uri: "https://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/000244272600114",
        # :sw_id=>"52846721",
        # :issn=>"0002-8762",
        #
        # :documenttypes_sw=>["Book Review"],
        # :type=>"article",

        # Example MEDLINE record has "normalized_doctypes"
        #   <fullrecord_metadata>
        #     <normalized_doctypes count='2'>
        #       <doctype>Other</doctype>
        #       <doctype>Article</doctype>
        #     </normalized_doctypes>

        #[doctypes, [pub_info['pubtype']]].flatten
        types = rec.doctypes
        types << rec.pub_info['pubtype'] if rec.pub_info['pubtype'].present?
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

      # Parse the WOS names and return a Hash compatible with Csl::AuthorName
      # @return [Hash]
      def pub_hash_names
        rec.names.map do |name|
          name = name.slice('first_name', 'middle_name', 'last_name', 'full_name', 'role').symbolize_keys
          match = name[:first_name].to_s.match(/\A([A-Z])([A-Z])/)
          if match
            # first_name is the initials, with first and middle initials combined
            name[:first_name] = match[1]
            name[:middle_name] ||= match[2]
          end
          name
        end
        # MEDLINE data might have a different form, e.g.
        # <name display='Y' role='author' seq_no='2'>
        #   <display_name>Altman, Russ B</display_name>
        #   <full_name>Altman, Russ B</full_name>
        #   <initials>RB</initials>
        # </name>
      end

  end
end
