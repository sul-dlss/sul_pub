module WebOdScience
  module Services
    module HashMappers
      class PublishersMapper

        def map_publisher_to_hash(record)
          pub_hash_publisher(record)
        end

        private

          # Extract publisher information into these fields:
          # :publisher=>"OXFORD UNIV PRESS"
          # :city=>"OXFORD"
          # :stateprovince=>""
          # :country=>"UNITED KINGDOM"
          def pub_hash_publisher(record)
            return if record.publishers.blank?
            pub = {}
            publisher = record.publishers.first
            pub[:publisher] = publisher['full_name']
            pub.merge(publisher_address(record, publisher['address']))
          end

          # Useful snippet to see a bunch of addresses
          # altman_records = WOS.queries.search_by_name('Altman, Russ, B', ['Stanford University']);
          # addresses = altman_records.map {|rec| rec.publishers.blank? ? {} : rec.publishers.first['address'] }
          # To see non-USA addresses
          # addresses.reject {|add| add['full_address'] =~ /USA/ }
          # @param address [Hash]
          def publisher_address(record, address)
            return if address.blank?
            pub = {}
            pub[:city] = address['city']
            full_address = address['full_address']
            pub.merge(publisher_state(full_address)).merge(publisher_country(record, full_address))
          end

          # Extract a state from "{state} {zip} [{country}]"
          # This could be a US address that did not parse or it is an international address.
          # A best guess at the country comes from the last CSV element:
          def publisher_country(record, full_address)
            return if medline_country(record)
            return if usa_address(full_address)
            country = full_address.split(',').last.to_s.strip
            if country.end_with?('USA')
              pub[:country] = 'USA'
            elsif country.present?
              pub[:country] = country #unless country =~ /[0-9]*/
            end
          end

          def medline_country(record)
            return false unless record.database == 'MEDLINE'
            country = record.doc.xpath('/REC/static_data/item/MedlineJournalInfo/Country')
            pub[:country] = country.text if country.present?
            country.present?
          end

          # Extract a state from "{state} {zip} [{country}]"
          # Some US addresses escape the StreetAddress parser.
          # Most often, the state acronym is in the last CSV element.
          def publisher_state(full_address)
            return if usa_address(full_address)
            state = full_address.split(',').last.to_s.strip
            matches = state.match(/([A-Z]{2})\s+([0-9-]*)/)
            pub[:stateprovince] = matches[1] if matches.present?
          end

          # Extract the state and country from a US address
          def usa_address(full_address)
            @usa_address ||= StreetAddress::US.parse(full_address)
            return false if @usa_address.blank?
            pub[:stateprovince] = @usa_address.state
            pub[:country] = 'USA'
            true
          end
      end
    end
  end
end


