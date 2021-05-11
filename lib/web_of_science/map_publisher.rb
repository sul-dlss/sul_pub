require 'street_address'

module WebOfScience

  # WOS publisher information
  class MapPublisher < Mapper

    attr_reader :publishers

    # Map WOS publisher data into the SUL PubHash data
    def pub_hash
      pub
    end

    private

      attr_reader :pub, :medline_country

      # Extract content from record, try not to hang onto the entire record
      # @param rec [WebOfScience::Record]
      def extract(rec)
        super(rec)
        @publishers = extract_publishers(rec)
        @medline_country = extract_medline_country(rec)
        @pub = pub_hash_publisher
      end

      def extract_medline_country(rec)
        return '' unless database == 'MEDLINE'
        country = rec.doc.xpath('/REC/static_data/item/MedlineJournalInfo/Country')
        country.present? ? country.text : ''
      end

      def extract_publishers(rec)
        publishers = rec.doc.search('static_data/summary/publishers/publisher').map do |publisher|
          # parse the publisher address(es)
          addresses = publisher.search('address_spec').map do |address|
            WebOfScience::XmlParser.attributes_with_children_hash(address)
          end
          addresses.sort! { |a| a['addr_no'].to_i }
          # parse the publisher name(s)
          names = publisher.search('names/name').map do |name|
            WebOfScience::XmlParser.attributes_with_children_hash(name)
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

      # Extract publisher information into these fields:
      # :publisher=>"OXFORD UNIV PRESS"
      # :city=>"OXFORD"
      # :stateprovince=>""
      # :country=>"UNITED KINGDOM"
      def pub_hash_publisher
        return {} if publishers.blank?
        # The WOS record allows for multiple publishers, for some reason, but journals usually have only one
        # publisher and our other data sources only provide one publisher; so choose the first one here.
        publisher = publishers.first
        data = {}
        data[:publisher] = publisher['full_name']
        data.update publisher_address(publisher['address'])
        data
      end

      # @param address [Hash]
      def publisher_address(address)
        return {} if address.blank?
        addr = {}
        addr[:city] = address['city']
        addr.update publisher_state_country(address['full_address'])
        addr
      end

      # @param full_address [Hash]
      def publisher_state_country(full_address)
        return {} if full_address.blank?
        addr = {}
        addr[:country] = medline_country if medline_country.present?
        usa_address = StreetAddress::US.parse(full_address)
        if usa_address
          addr[:stateprovince] = usa_address.state
          addr[:country] ||= 'USA'
        end
        addr[:stateprovince] ||= parse_state(full_address)
        addr[:country] ||= parse_country(full_address)
        addr
      end

      # Extract a state from "{state} {zip} [{country}]"
      def parse_country(full_address)
        # This could be a US address that did not parse or it is an international address.
        # A best guess at the country comes from the last CSV element:
        country = full_address.split(',').last.to_s.strip
        if country.end_with?('USA')
          'USA'
        elsif country.present? && country !~ /[0-9]*/
          country
        end
      end

      # Extract a state from "{state} {zip} [{country}]"
      def parse_state(full_address)
        # Some US addresses escape the StreetAddress parser.
        # Most often, the state acronym is in the last CSV element.
        state = full_address.split(',').last.to_s.strip
        matches = state.match(/([A-Z]{2})\s+([0-9-]*)/)
        matches[1] if matches.present?
      end

  end
end
