class DoiSearch

  def self.search doi
    results = Publication.find_by_doi doi
    if results.none? { |pub| pub.authoritative_doi_source? }
      results += ScienceWireClient.new.get_pub_by_doi(doi)
    end
    if results.size > 1
      results.reject! {|pub| non_sw_pub pub}
    end
    results
  end

  # @return [Boolean] true if the pub is not from sciencwire
  def self.non_sw_pub pub
    return false if pub.is_a? Hash # Hashes are returned from the SW only query

    if pub.authoritative_doi_source?
      false
    else
      true
    end
  end


end
