module Csl

  class CapMapper

    # Convert CAP authors into CSL authors
    # @param [Array<Hash>] authors array of hash data
    # @return [Array<Hash>] CSL authors array of hash data
    def self.authors_to_csl(authors)
      # All the CAP authors are an author if they have no role or they have an 'author' role
      authors = authors.map(&:symbolize_keys)
      authors.select! { |author| author[:role].nil? || author[:role].to_s.downcase.eql?('author') }
      authors.map { |author| Csl::AuthorName.new(author).to_csl_author }
    end

    # Convert CAP editors into CSL editors
    # @param [Array<Hash>] authors array of hash data
    # @return [Array<Hash>] CSL authors array of hash data
    def self.editors_to_csl(authors)
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
    def self.create_csl_report(pub_hash, authors = [], editors = [])
      csl_report = {}
      csl_report['id'] = 'sulpub'
      csl_report['type'] = 'report'
      csl_report['author'] = authors if authors.present?
      csl_report['editor'] = editors if editors.present?
      csl_report['title'] = pub_hash[:title] if pub_hash[:title].present?
      csl_report['abstract'] = pub_hash[:abstract] if pub_hash[:abstract].present?
      csl_report['publisher'] = pub_hash[:publisher] if pub_hash[:publisher].present?
      csl_report['publisher-place'] = pub_hash[:publicationSource] if pub_hash[:publicationSource].present?
      # Date Accessed -> accessed
      if pub_hash[:year].present?
        csl_report['issued'] = {
          'date-parts' => [[ pub_hash[:year] ]]
        }
      end
      url = pub_hash[:publicationUrl]
      csl_report['URL'] = url if url.present?
      series = pub_hash[:series]
      if series.present?
        csl_report['collection-title'] = series[:title] if series[:title].present?
        csl_report['volume'] = series[:volume] if series[:volume].present?
        csl_report['number'] = series[:number] if series[:number].present?
      end
      csl_report['page'] = pub_hash[:pages] if pub_hash[:pages].present?
      csl_report
    end
  end
end
