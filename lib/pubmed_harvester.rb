
class PubmedHarvester

  # Searches locally, then ScienceWire, then Pubmed for a publication by PubmedId
  # @param [String] pmid PubmedId
  # @return [Array<Hash>] publication in BibJson format.  Usually for Publication sourcelookup requests
  #   If no publication found, returns an empty Array
  def self.search_all_sources_by_pmid pmid
    result = []

    Publication.where(:pmid => pmid).each do |pub|
      result << pub.pub_hash
    end

    if result.empty?
      sw_records_doc = ScienceWireClient.new.pull_records_from_sciencewire_for_pmids(pmid)
      sw_records_doc.xpath('//PublicationItem').each do |sw_doc|
        result << SciencewireSourceRecord.convert_sw_publication_doc_to_hash(sw_doc)
      end

      # TODO augment with pubmed mesh and abstracts?
    end

    if result.empty?
      pm_xml = PubmedClient.new.fetch_records_for_pmid_list pmid
      Nokogiri::XML(pm_xml).xpath('//PubmedArticle').each do |doc|
        pm_rec = PubmedSourceRecord.new
        result << pm_rec.convert_pubmed_publication_doc_to_hash(doc)
      end
    end

    result.each do |pub_hash|
      h = PubHash.new(pub_hash)

      pub_hash[:apa_citation] = h.to_apa_citation unless pub_hash[:apa_citation]
      pub_hash[:mla_citation] = h.to_mla_citation unless pub_hash[:mla_citation]
      pub_hash[:chicago_citation] = h.to_chicago_citation unless pub_hash[:chicago_citation]
    end

    result
  end
end
