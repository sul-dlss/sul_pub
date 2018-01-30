require 'identifiers'

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
    results = web_of_science(doi)
    if results.present?
      name = doi_name(doi)
      match = results.find { |pub_hash| doi_name(pub_hash[:doi]) == name }
      return [match] if match.present?
    end
    # Everything else is non-authoritative
    results.unshift(pub.pub_hash) if pub
    results
  end

  # Retrieve records from the Web of Science
  # Web of Science results are based on partial string matching for DOI queries, unfortunately.
  # @see WebOfScience::Queries#search_by_doi
  # @param [String] doi
  # @return [Array<Hash>] matching hashes
  def self.web_of_science(doi)
    return [] unless Settings.WOS.enabled
    doi = doi_name(doi)
    return [] if doi.blank?
    retriever = WebOfScience.queries.search_by_doi(doi)
    retriever.next_batch.map { |record| add_citation(record.pub_hash) }
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

  # @param [String, nil] doi
  # @return [String, nil] DOI name
  def self.doi_name(doi)
    ::Identifiers::DOI.extract_one(doi)
  end
  private_class_method :doi_name
end
