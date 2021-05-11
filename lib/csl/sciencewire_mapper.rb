module Csl
  # Convert ScienceWire content into a CSL format
  class SciencewireMapper
    # Convert ScienceWire authors into CSL authors, see also
    # SciencewireSourceRecord.convert_sw_publication_doc_to_hash
    # @param [Array<Hash>] authors array of hash data
    # @return [Array<Hash>] CSL authors array of hash data
    def self.authors_to_csl(authors)
      # ScienceWire AuthorList is split('|') into an array of authors
      authors.map do |author|
        # Each ScienceWire author is a CSV value: 'Lastname,Firstname,Middlename'
        last, first, middle = author[:name].split(',')
        Csl::AuthorName.new(
          lastname: last,
          firstname: first,
          middlename: middle
        ).to_csl_author
      end.compact
    end
  end
end
