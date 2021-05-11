# frozen_string_literal: true

module WebOfScience
  # Map WOS record citation data into the SUL PubHash data
  class MapCitation
    attr_reader :pub_hash # [Hash<Symbol => [String, Hash]>]

    # @param rec [WebOfScience::Record]
    def initialize(rec)
      raise(ArgumentError, 'rec must be a WebOfScience::Record') unless rec.is_a? WebOfScience::Record

      @pub_hash = {}
      extract(rec)
    end

    private

    # Extract content from record, try not to hang onto the entire record
    # Builds the pub_hash
    # @param rec [WebOfScience::Record]
    def extract(rec)
      pub_info = rec.pub_info
      titles = rec.titles
      pages = extract_pages(pub_info['page'])
      pub_hash[:pages] = pages if pages.present?
      pub_hash.merge!(
        year: pub_info['pubyear'],
        date: pub_info['sortdate'],
        title: titles['item'].strip,
        journal: extract_journal(pub_info, titles['source'], extract_issns(rec), pages)
      )
    end

    # Journal EISSN and/or ISSN
    # @return [Array<Hash<Symbol => String>>]
    def extract_issns(rec)
      rec.identifiers.pub_hash.select { |id| id[:type] == 'issn' || id[:type] == 'eissn' }
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
