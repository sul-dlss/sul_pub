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

    WebOfScience.queries.search_by_doi(doi).next_batch.map(&:pub_hash)
  end

  # @param [String, nil] doi
  # @return [String, nil] DOI name
  def self.doi_name(doi)
    ::Identifiers::DOI.extract(doi).first
  end
  private_class_method :doi_name
end
