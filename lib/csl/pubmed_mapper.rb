module Csl
  # Convert PubMed content into a CSL format
  class PubmedMapper
    # Convert PubMed authors into CSL authors, see also
    # PubmedSourceRecord.convert_pubmed_publication_doc_to_hash
    # @param [Array<Hash>] authors array of hash data
    # @return [Array<Hash>] CSL authors array of hash data
    def self.authors_to_csl(authors)
      authors.map do |author|
        author = author.symbolize_keys
        Csl::AuthorName.new(author).to_csl_author
      end.compact
    end
  end
end
