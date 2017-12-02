require 'street_address'
module WebOfScience
  module Services
    module HashMappers
      class PublishersMapper

        # Extract publisher information into these fields:
        # :publisher=>"OXFORD UNIV PRESS"
        # :city=>"OXFORD"
        # :stateprovince=>""
        # :country=>"UNITED KINGDOM"
        def map_publisher_to_hash(record)
          return {} if record.publishers.blank?
          pub = {}
          publisher = record.publishers.first
          pub[:publisher] = publisher['full_name']
          pub.merge(map_publisher_address_to_hash(record, publisher['address']))
          pub
        end

        private

          # Useful snippet to see a bunch of addresses
          # altman_records = WOS.queries.search_by_name('Altman, Russ, B', ['Stanford University']);
          # addresses = altman_records.map {|rec| rec.publishers.blank? ? {} : rec.publishers.first['address'] }
          # To see non-USA addresses
          # addresses.reject {|add| add['full_address'] =~ /USA/ }
          # @param address [Hash]
          def map_publisher_address_to_hash(record, address)
            return {} if address.blank?
            pub = {}
            pub[:city] = address['city']
            full_address = address['full_address']
            pub.merge(map_publisher_state_to_hash(full_address)).merge(map_publisher_country_to_hash(record, full_address))
            pub
          end

          # Extract a state from "{state} {zip} [{country}]"
          # Some US addresses escape the StreetAddress parser.
          # Most often, the state acronym is in the last CSV element.
          def map_publisher_state_to_hash(full_address)
            pub = map_usa_address_to_hash(full_address).blank?
            return {} if pub.blank?
            state = full_address.split(',').last.to_s.strip
            matches = state.match(/([A-Z]{2})\s+([0-9-]*)/)
            pub[:stateprovince] = matches[1] if matches.present?
            pub
          end

          # Extract the state and country from a US address
          def map_usa_address_to_hash(full_address)
            usa_address ||= StreetAddress::US.parse(full_address)
            return {} if usa_address.blank?
            pub = {}
            pub[:stateprovince] = usa_address.state
            pub[:country] = 'USA'
            pub
          end

          # Extract a state from "{state} {zip} [{country}]"
          # This could be a US address that did not parse or it is an international address.
          # A best guess at the country comes from the last CSV element:
          def map_publisher_country_to_hash(record, full_address)
            med_pub = map_medline_country_to_hash(record)
            return {} if med_pub.blank?

            usa_adress_pub = map_usa_address_to_hash(full_address)
            return {} if usa_adress_pub.blank?

            pub     = med_pub.merge(usa_adress_pub)
            country = full_address.split(',').last.to_s.strip

            if country.end_with?('USA')
              pub[:country] = 'USA'
            elsif country.present?
              pub[:country] = country #unless country =~ /[0-9]*/
            end

            pub
          end

          def map_medline_country_to_hash(record)
            return unless record.database == 'MEDLINE'
            pub = {}
            country = record.doc.xpath('/REC/static_data/item/MedlineJournalInfo/Country')
            pub[:country] = country.text if country.present?
            pub
          end
      end
    end
  end
end


