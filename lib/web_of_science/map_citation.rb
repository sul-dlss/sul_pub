module WebOfScience
  # Map WOS record citation data into the SUL PubHash data
  class MapCitation
    # @param rec [WebOfScience::Record]
    def initialize(rec)
      raise(ArgumentError, 'rec must be a WebOfScience::Record') unless rec.is_a? WebOfScience::Record
      extract(rec)
    end

    # publication citation details
    # @return [Hash]
    def pub_hash
      c = {}
      c[:pages] = pages if pages.present?
      c.merge(
        year: year,
        date: date,
        title: title,
        journal: journal
      )
    end

    private

      attr_reader :date
      attr_reader :journal
      attr_reader :pages
      attr_reader :title
      attr_reader :year

      # Extract content from record, try not to hang onto the entire record
      # @param rec [WebOfScience::Record]
      def extract(rec)
        issn = extract_issn(rec)
        pub_info = rec.pub_info
        titles = rec.titles
        @title = titles['item'].strip
        @year = pub_info['pubyear']
        @date = pub_info['sortdate']
        @pages = extract_pages(pub_info['page'])
        @journal = extract_journal(pub_info, titles['source'], issn, pages)
      end

      # Journal EISSN or ISSN
      # @return [Hash]
      def extract_issn(rec)
        pub_hash = rec.identifiers.pub_hash
        pub_hash.find { |id| id[:type] == 'issn' } || pub_hash.find { |id| id[:type] == 'eissn' }
      end

      # Journal information
      # @return [Hash]
      def extract_journal(pub_info, name, issn, pages)
        j = {}
        j[:name] = name.strip if name.present?
        j[:volume] = pub_info['vol'] if pub_info['vol'].present?
        j[:issue] = pub_info['issue'] if pub_info['issue'].present?
        j[:pages] = pages if pages.present?
        j[:identifier] = issn if issn.present?
        j
      end

      # @return [String]
      def extract_pages(page)
        return if page.blank?
        fst = page['begin'].to_s.strip
        lst = page['end'].to_s.strip
        fst == lst ? fst : [fst, lst].select(&:present?).join('-')
      end
  end
end
