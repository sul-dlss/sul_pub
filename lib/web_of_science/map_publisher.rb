require 'street_address'

module WebOfScience

  # WOS publisher information
  class MapPublisher < Mapper

    # @return publishers [Array<Hash>]
    def publishers
      @publishers ||= begin
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
    end

    private

      attr_reader :pub

      # Map WOS publisher data into the SUL PubHash data
      def mapper
        @pub || begin
          @pub = {}
          pub_hash_publisher
          pub
        end
      end

      # Extract publisher information into these fields:
      # :publisher=>"OXFORD UNIV PRESS"
      # :city=>"OXFORD"
      # :stateprovince=>""
      # :country=>"UNITED KINGDOM"
      def pub_hash_publisher
        return if publishers.blank?
        # The WOS record allows for multiple publishers, for some reason, but journals usually have only one
        # publisher and our other data sources only provide one publisher; so choose the first one here.
        publisher = publishers.first
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
