require 'street_address'

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
        pub_hash_publisher
      end

      # publication citation details
      def pub_hash_citation
        pub[:year] = rec.pub_info['pubyear']
        pub[:date] = rec.pub_info['sortdate']
        pub[:pages] = pub_hash_pages if pub_hash_pages.present?
        pub[:title] = rec.titles['item']
        pub[:journal] = pub_hash_journal
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

      # Journal information
      # @return [Hash]
      def pub_hash_journal
        identifier = rec.identifiers.pub_hash.select { |id| id['type'] == 'issn' }
        h = {}
        h[:name] = rec.titles['source'] if rec.titles['source'].present?
        h[:volume] = rec.pub_info['vol'] if rec.pub_info['vol'].present?
        h[:issue] = rec.pub_info['issue'] if rec.pub_info['issue'].present?
        h[:pages] = pub_hash_pages if pub_hash_pages.present?
        h[:identifier] = identifier if identifier.present?
        h
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

      # @return [String]
      def pub_hash_pages
        @pub_hash_pages ||= begin
          page = rec.pub_info['page']
          return if page.blank?
          fst = page['begin']
          lst = page['end']
          fst == lst ? fst : [fst, lst].join('-')
        end
      end

      # Extract publisher information into these fields:
      # :publisher=>"OXFORD UNIV PRESS"
      # :city=>"OXFORD"
      # :stateprovince=>""
      # :country=>"UNITED KINGDOM"
      def pub_hash_publisher
        return if rec.publishers.blank?
        # The WOS record allows for multiple publishers, for some reason, but journals usually have only one
        # publisher and our other data sources only provide one publisher; so choose the first one here.
        publisher = rec.publishers.first
        pub[:publisher] = publisher['full_name']
        publisher_address(publisher['address'])
      end

      # Useful snippet to see a bunch of addresses
      # altman_records = WOS.queries.search_by_name('Altman, Russ, B', ['Stanford University']);
      # addresses = altman_records.map {|rec| rec.publishers.blank? ? {} : rec.publishers.first['address'] }
      # To see non-USA addresses
      # addresses.reject {|add| add['full_address'] =~ /USA/ }

      # @param address [Hash]
      def publisher_address(address)
        return if address.blank?
        # The city is provided by WOS
        pub[:city] = address['city']
        # The rest is a parsing game
        full_address = address['full_address']
        publisher_state(full_address)
        publisher_country(full_address)
      end

      def medline_country
        return false unless rec.database == 'MEDLINE'
        country = rec.doc.xpath('/REC/static_data/item/MedlineJournalInfo/Country')
        pub[:country] = country.text if country.present?
        country.present?
      end

      # Extract a state from "{state} {zip} [{country}]"
      def publisher_country(full_address)
        return if medline_country
        return if usa_address(full_address)
        # This could be a US address that did not parse or it is an international address.
        # A best guess at the country comes from the last CSV element:
        country = full_address.split(',').last.to_s.strip
        if country.end_with?('USA')
          pub[:country] = 'USA'
        elsif country.present?
          pub[:country] = country #unless country =~ /[0-9]*/
        end
      end

      # Extract a state from "{state} {zip} [{country}]"
      def publisher_state(full_address)
        return if usa_address(full_address)
        # Some US addresses escape the StreetAddress parser.
        # Most often, the state acronym is in the last CSV element.
        state = full_address.split(',').last.to_s.strip
        matches = state.match(/([A-Z]{2})\s+([0-9-]*)/)
        pub[:stateprovince] = matches[1] if matches.present?
      end

      # Extract the state and country from a US address
      def usa_address(full_address)
        @usa_address ||= StreetAddress::US.parse(full_address)
        return false if @usa_address.blank?
        # This is a US address
        pub[:stateprovince] = @usa_address.state
        pub[:country] = 'USA'
        true
      end

  end
end
