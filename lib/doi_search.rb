class DoiSearch
  # The first authoritative result(s) are returned.
  # If an authoritative local match is found, no remote services are hit.
  # WoS hits need to be post-processed because the API does partial string
  # matching for DOI queries, unfortunately.
  # @param [String] doi
  # @return [Array<Hash>] matching hashes
  def self.search(doi)
    pub = Publication.find_by_doi(doi)
    return [pub.pub_hash] if pub && pub.authoritative_doi_source?
    if Settings.SCIENCEWIRE.enabled
      sw_hits = ScienceWireClient.new.get_pub_by_doi(doi)
      return sw_hits unless sw_hits.empty?
    end
    results = []
    if Settings.WOS.enabled
      results += WebOfScience.queries.search_by_doi(doi).map { |rec| add_citation(rec.pub_hash) }
      full_match = normalized_dois(results)[normalized_doi(doi)]
      return [full_match] if full_match
    end
    # Everything else is non-authoritative
    results.unshift(pub.pub_hash) if pub
    results
  end

  # @param [Hash] pub_hash modifies passed hash to include citation k/v pairs
  # @return [Hash] the same modified hash
  def self.add_citation(pub_hash)
    cite = Csl::Citation.new(pub_hash)
    pub_hash[:apa_citation] ||= cite.to_apa_citation
    pub_hash[:mla_citation] ||= cite.to_mla_citation
    pub_hash[:chicago_citation] ||= cite.to_chicago_citation
    pub_hash
  end
  private_class_method :add_citation

  # @param [Array<Hash>] pub_hashes WOS pub_hashes
  # @return [Hash<String => Hash>] normalized DOI strings mapped to pub_hashes
  # pub_hash[:identifier].select{|h| h[:type] == 'doi'}}}
  # [{:type=>"doi", :id=>"10.1172/jci.insight.87623", :url=>"https://dx.doi.org/10.1172/jci.insight.87623"}]
  def self.normalized_dois(pub_hashes)
    Hash[pub_hashes.map { |h| normalized_doi(h[:doi]) }.zip(pub_hashes)]
      .select { |k| k } # exclude nil key(s) (normalization fail)
  end
  private_class_method :normalized_dois

  # @param [String, nil] doi
  # @return [String, nil] normalized DOI string
  def self.normalized_doi(doi)
    Identifiers::DOI.extract(doi).first
  end
  private_class_method :normalized_doi
end
