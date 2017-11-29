
module WebOfScience

  module XmlUtil

    class XmlExtractor

      # @return identifiers [Hash<String => String>]
      def extract_identifiers(doc)
        WebOfScience::Data::Identifiers.new(doc)
      end

      # @return [String|nil]
      def extract_doi(identifiers)
        identifiers.doi
      end

      # @return [String|nil]
      def extract_pmid(identifiers)
        identifiers.pmid
      end

      # @return [String|nil]
      def extract_issn(identifiers)
        identifiers.issn
      end

      # @return uid [String] the UID
      def extract_uid(doc)
        doc.search('UID').text
      end

      # Extract the {WOS_ITEM_ID} from a WOS-UID in the form {DB_PREFIX}:{WOS_ITEM_ID}
      # @return [String]
      def extract_wos_item_id(identifiers)
        identifiers.wos_item_id
      end

      # Extract the {DB_PREFIX} from a WOS-UID in the form {DB_PREFIX}:{WOS_ITEM_ID}
      # @return [String|nil]
      def extract_database(identifiers)
        identifiers.database
      end

      # @return names [Array<Hash<String => String>>]
      def extract_names(doc)
        names = doc.search('static_data/summary/names/name').map do |name|
          attributes_with_children_hash(name)
        end
        names.sort { |name| name['seq_no'].to_i }
      end

      # @return authors [Array<Hash<String => String>>]
      def extract_authors(names)
        names.select { |name| name['role'] == 'author' }
      end

      # @return abstracts [Array<Hash<String => String>>]
      def extract_abstracts(doc)
        doc.search('static_data/fullrecord_metadata/abstracts/abstract/abstract_text').map(&:text)
      end

      # @return doctypes [Array<String>]
      def extract_doctypes(doc)
        doc.search('static_data/summary/doctypes/doctype').map(&:text)
      end

      # @return pub_info [Hash<String => String>]
      def extract_pub_info(doc)
        info = doc.at('static_data/summary/pub_info')
        fields = attributes_map(info)
        fields += info.children.map do |child|
          [child.name, attributes_map(child).to_h ]
        end
        fields.to_h
      end

      # @return publishers [Array<Hash>]
      def extract_publishers(doc)
        publishers = doc.search('static_data/summary/publishers/publisher').map do |publisher|
          # parse the publisher address(es)
          addresses = publisher.search('address_spec').map do |address|
            attributes_with_children_hash(address)
          end
          addresses.sort! { |a| a['addr_no'].to_i }
          # parse the publisher name(s)
          names = publisher.search('names/name').map do |name|
            attributes_with_children_hash(name)
          end
          # associate each publisher name with it's address by 'addr_no'
          names.each do |name|
            address = addresses.find { |addr| addr['addr_no'] == name['addr_no'] }
            name['address'] = address
          end
          names.sort { |name| name['seq_no'].to_i }
        end
        publishers.flatten
      end

      # @return titles [Hash<String => String>]
      def extract_titles(doc)
        titles = doc.search('static_data/summary/titles/title')
        titles.map { |title| [title['type'], title.text] }.to_h
      end

      private

        XML_OPTIONS = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

        # @param element [Nokogiri::XML::Element]
        # @return attributes [Array<Array[String, String]>]
        def attributes_map(element)
          element.attributes.map { |name, att| [name, att.value] }
        end

        # @param element [Nokogiri::XML::Element]
        # @return fields [Hash]
        def attributes_with_children_hash(element)
          fields = attributes_map(element)
          fields += element.children.map { |c| [c.name, c.text] }
          fields.to_h
        end

    end

  end

end


