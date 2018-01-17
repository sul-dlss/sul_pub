class PubmedHarvester
  # Searches locally (twice), then ScienceWire, then Pubmed for a publication by PubmedId
  # Is paranoid, searches both publications and publication_identifiers identifiers for pmid
  # @param [String] pmid Pubmed ID
  # @return [Array<Hash>] publications in BibJson format or, if none found, an empty Array
  def self.search_all_sources_by_pmid(pmid)
    result = Publication.where(pmid: pmid).to_a # TODO: index manual and batch with pmid?
    result = [Publication.find_by_pmid_pub_id(pmid)].compact if result.empty?

    if result.none?(&:authoritative_pmid_source?)
      sw_records_doc = ScienceWireClient.new.pull_records_from_sciencewire_for_pmids(pmid)
      sw_records_doc.xpath('//PublicationItem').each do |sw_doc|
        result << SciencewireSourceRecord.convert_sw_publication_doc_to_hash(sw_doc)
      end

      if result.none? { |p| p.is_a? Hash }
        pm_xml = PubmedClient.new.fetch_records_for_pmid_list(pmid)
        Nokogiri::XML(pm_xml).xpath('//PubmedArticle').each do |doc|
          result << PubmedSourceRecord.new.convert_pubmed_publication_doc_to_hash(doc)
        end
      end
    end

    # If we have more than one result, we could have a mix of local and pubmed/SW records
    # Only clean out manual/batch if there's a mix
    if result.size > 1 && result.any? { |p| p.is_a? Hash }
      result.reject! do |pub|
        pub.is_a?(Publication) && pub.pub_hash[:provanance] =~ /cap|batch/i
      end
    end

    # Turn everything into a pub_hash, then generate citations if needed
    result.map do |pub|
      pub_hash = pub.respond_to?(:pub_hash) ? pub.pub_hash : pub
      cite = Csl::Citation.new(pub_hash)
      pub_hash[:apa_citation] ||= cite.to_apa_citation
      pub_hash[:mla_citation] ||= cite.to_mla_citation
      pub_hash[:chicago_citation] ||= cite.to_chicago_citation
      pub_hash
    end
  end
end
