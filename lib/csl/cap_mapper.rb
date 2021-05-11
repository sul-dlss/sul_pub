# frozen_string_literal: true

module Csl
  class CapMapper
    class << self
      # Convert CAP authors into CSL authors
      # @param [Array<Hash>] authors array of hash data
      # @return [Array<Hash>] CSL authors array of hash data
      def authors_to_csl(authors)
        # All the CAP authors are an author if they have no role or they have an 'author' role
        authors = authors.map(&:symbolize_keys)
        authors.select! { |author| author[:role].nil? || author[:role].to_s.downcase.eql?('author') }
        authors.map { |author| Csl::AuthorName.new(author).to_csl_author }
      end

      # Convert CAP editors into CSL editors
      # @param [Array<Hash>] authors array of hash data
      # @return [Array<Hash>] CSL authors array of hash data
      def editors_to_csl(authors)
        # A CAP editor has an 'editor' role
        editors = authors.map(&:symbolize_keys)
        editors.select! { |editor| editor[:role].to_s.downcase.eql?('editor') }
        editors.map { |editor| Csl::AuthorName.new(editor).to_csl_author }
      end

      # Report – A document containing the findings of an individual or group.
      # Can include a technical paper, publication, issue brief, or working paper.
      #
      # The Zotero and Mendeley mappings to a CSL report guided this implementation, see
      # http://aurimasv.github.io/z2csl/typeMap.xml#map-report
      # http://support.mendeley.com/customer/portal/articles/364144-csl-type-mapping
      #
      # @param [Hash] pub_hash from Publication.pub_hash data
      # @param [Array<Hash>] authors
      # @param [Array<Hash>] editors
      # @return [Hash] CSL report information
      def create_csl_report(pub_hash, authors = [], editors = [])
        csl_report = {}
        csl_report['id'] = 'sulpub'
        csl_report['type'] = 'report'
        csl_report.update(extract_agents(pub_hash, authors, editors))
        csl_report.update(extract_pub_info(pub_hash))
        csl_report.update(extract_series(pub_hash))
        csl_report
      end

      private

      # @return [Hash] CSL publication title, abstract, date, pages, etc.
      def extract_pub_info(pub_hash)
        map = {}
        map['title'] = pub_hash[:title] if pub_hash[:title].present?
        map['abstract'] = pub_hash[:abstract] if pub_hash[:abstract].present?
        map['issued'] = { 'date-parts' => [[pub_hash[:year]]] } if pub_hash[:year].present?
        map['URL'] = pub_hash[:publicationUrl] if pub_hash[:publicationUrl].present?
        map['page'] = pub_hash[:pages] if pub_hash[:pages].present?
        map
      end

      # @return [Hash] CSL author, editor, and publisher data
      def extract_agents(pub_hash, authors, editors)
        map = {}
        map['author'] = authors if authors.present?
        map['editor'] = editors if editors.present?
        map.update extract_publisher(pub_hash)
        map
      end

      # @return [Hash] CSL publisher data
      def extract_publisher(pub_hash)
        map = {}
        map['publisher'] = pub_hash[:publisher] if pub_hash[:publisher].present?
        map['publisher-place'] = pub_hash[:publicationSource] if pub_hash[:publicationSource].present?
        map
      end

      # @return [Hash] CSL series data
      def extract_series(pub_hash)
        map = {}
        return map if pub_hash[:series].blank?

        series = pub_hash[:series]
        map['collection-title'] = series[:title] if series[:title].present?
        map['volume'] = series[:volume] if series[:volume].present?
        map['number'] = series[:number] if series[:number].present?
        map
      end
    end
  end
end
