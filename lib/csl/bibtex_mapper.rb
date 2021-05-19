# frozen_string_literal: true

module Csl
  # Convert BibtexIngester content into a CSL format
  # NOTE: BibtexIngester was removed by https://github.com/sul-dlss/sul_pub/pull/1317 (commit fb4b3fc9a74a6f188673ac171dc0b72c1cc0fc93)
  class BibtexMapper
    # Convert BibtexIngester authors into CSL authors
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
