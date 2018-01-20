class DoiSearch
  def self.search(doi)
    results = [Publication.find_by_doi(doi)].compact
    results += ScienceWireClient.new.get_pub_by_doi(doi) if results.none?(&:authoritative_doi_source?)
    results.reject! { |pub| non_sw_pub pub } if results.size > 1
    results
  end

  # @return [Boolean] true if the pub is not from sciencewire
  def self.non_sw_pub(pub)
    return false if pub.is_a? Hash # Hashes are returned from the SW only query
    !pub.authoritative_doi_source?
  end
  private_class_method :non_sw_pub
end
