module WebOfScience

  module Services

    module HashMappers

      class CitationMapper

        def map_citation_to_hash(record)
          c = {}
          c[:year] = record.pub_info['pubyear']
          c[:date] = record.pub_info['sortdate']
          c[:pages] = map_pages_to_hash(record)
          c[:title] = record.titles['item']
          c[:journal] = map_journal_to_hash(record)
          c
        end

        private

          # Journal information
          # @return [Hash]
          def map_journal_to_hash(record)
            j = {}
            j[:name] = record.titles['source'] if record.titles['source'].present?
            j[:volume] = record.pub_info['vol'] if record.pub_info['vol'].present?
            j[:issue] = record.pub_info['issue'] if record.pub_info['issue'].present?
            j[:pages] = map_pages_to_hash(record)
            issn = map_journal_identifier_to_hash(record)
            j[:identifier] = issn if issn.present?
            j
          end

          # Journal EISSN or ISSN
          # @return [Hash]
          def map_journal_identifier_to_hash(record)
            issn  = record.identifiers.pub_hash.find { |id| id[:type] == 'issn' }
            eissn = record.identifiers.pub_hash.find { |id| id[:type] == 'eissn' }
            issn || eissn
          end

          # @return [String]
          def map_pages_to_hash(record)
            page = record.pub_info['page']
            return nil if page.blank?
            fst = page['begin'].to_s.strip
            lst = page['end'].to_s.strip
            fst == lst ? fst : [fst, lst].select(&:present?).join('-')
          end

      end
    end
  end
end

