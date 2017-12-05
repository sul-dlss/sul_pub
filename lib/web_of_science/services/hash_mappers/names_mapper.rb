module WebOfScience
  module Services
    module HashMappers

      class NamesMapper

        # publication authors
        # @return [Hash]
        def map_names_to_hash(record)
          # - use names, with role, to include 'author' and other roles, possibly 'editor' also
          # - the PubHash class has methods to separate them when creating citations
          @names ||= {
            author: get_and_format_author_field_values_from_record_names(record),
            authorcount: record.authors.count
          }
        end

        private

          # Parse the WOS names and return a Hash compatible with Csl::AuthorName
          # @return [Hash]
          def get_and_format_author_field_values_from_record_names(rec)
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
  end
end
