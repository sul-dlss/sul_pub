
class PubmedHarvester

  # Searches locally, then ScienceWire, then Pubmed for a publication by PubmedId
  # @param [String] pmid PubmedId
  # @return [Array<Hash>] publication in BibJson format.  Usually for Publication sourcelookup requests
  #   If no publication found, returns an empty Array
  def self.search_all_sources_by_pmid pmid

    result = Publication.where(:pmid => pmid) # TODO index manual and batch with pmid?

    if result.none? { |p| p.authoritative_pmid_source? }
      sw_records_doc = ScienceWireClient.new.pull_records_from_sciencewire_for_pmids(pmid)
      sw_records_doc.xpath('//PublicationItem').each do |sw_doc|
        result << SciencewireSourceRecord.convert_sw_publication_doc_to_hash(sw_doc)
      end

      if result.none? {|p| p.is_a? Hash }
        pm_xml = PubmedClient.new.fetch_records_for_pmid_list pmid
        Nokogiri::XML(pm_xml).xpath('//PubmedArticle').each do |doc|
          pm_rec = PubmedSourceRecord.new
          result << pm_rec.convert_pubmed_publication_doc_to_hash(doc)
        end
      end
    end

    # If we have more than one result, we could have a mix of local and pubmed/SW records
    # Only clean out manual/batch if there's a mix
    if result.size > 1 && result.any? {|p| p.kind_of? Hash }
      result.reject! do |pub|
        if(pub.is_a?(Publication) && pub.pub_hash[:provanance] =~ /cap|batch/i)
          true
        else
          false
        end
      end
    end

    # Turn everything into a pub_hash, then generate citations if needed
    result.map! do |pub|
      pub_hash = (pub.pub_hash if pub.respond_to? :pub_hash) || pub
      h = PubHash.new(pub_hash)

      pub_hash[:apa_citation] = h.to_apa_citation unless pub_hash[:apa_citation]
      pub_hash[:mla_citation] = h.to_mla_citation unless pub_hash[:mla_citation]
      pub_hash[:chicago_citation] = h.to_chicago_citation unless pub_hash[:chicago_citation]
      pub_hash
    end

    result
  end
end
