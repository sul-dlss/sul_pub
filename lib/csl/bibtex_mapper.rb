# frozen_string_literal: true

module Csl
  # Convert BibTexIngester content into a CSL format
  class BibtexMapper
    # Convert BibTexIngester authors into CSL authors
    # @param [Array<Hash>] authors array of hash data
    # @return [Array<Hash>] CSL authors array of hash data
    def self.authors_to_csl(authors)
      authors.map do |author|
        author = author.symbolize_keys
        next if author[:name].blank?

        family, given = author[:name].split(',')
        { 'family' => family, 'given' => given }
      end
    end
  end
end
