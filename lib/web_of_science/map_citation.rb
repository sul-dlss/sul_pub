module WebOfScience

  # Map WOS record citation data into the SUL PubHash data
  class MapCitation < Mapper

    private

      # publication citation details
      # @return [Hash]
      def mapper
        @citation ||= begin
          c = {}
          c[:year] = rec.pub_info['pubyear']
          c[:date] = rec.pub_info['sortdate']
          c[:pages] = pages if pages.present?
          c[:title] = rec.titles['item']
          c[:journal] = journal
          c
        end
      end

      # Journal information
      # @return [Hash]
      def journal
        j = {}
        j[:name] = rec.titles['source'] if rec.titles['source'].present?
        j[:volume] = rec.pub_info['vol'] if rec.pub_info['vol'].present?
        j[:issue] = rec.pub_info['issue'] if rec.pub_info['issue'].present?
        j[:pages] = pages if pages.present?
        issn = journal_identifier
        j[:identifier] = issn if issn.present?
        j
      end

      # Journal EISSN or ISSN
      # @return [Hash]
      def journal_identifier
        issn  = rec.identifiers.pub_hash.find { |id| id[:type] == 'issn' }
        eissn = rec.identifiers.pub_hash.find { |id| id[:type] == 'eissn' }
        issn || eissn
      end

      # @return [String]
      def pages
        @pages ||= begin
          page = rec.pub_info['page']
          return if page.blank?
          fst = page['begin'].to_s.strip
          lst = page['end'].to_s.strip
          fst == lst ? fst : [fst, lst].select(&:present?).join('-')
        end
      end
  end
end
