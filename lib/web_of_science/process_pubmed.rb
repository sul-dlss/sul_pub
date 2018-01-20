module WebOfScience

  # This complements the WebOfScience::Harvester
  module ProcessPubmed

    # For WOS-records with a PMID, try to enhance them with PubMed data
    def pubmed_additions(records)
      records.select { |record| record.pmid.present? }.each do |record|
        begin
          pub = Publication.find_by(wos_uid: record.uid)
          pub.pmid = record.pmid
          pub.save
          pubmed_addition(record, pub) if record.database != 'MEDLINE'
        rescue StandardError => err
          message = "pubmed_additions failed for #{record.uid}"
          NotificationManager.error(err, message, self)
        end
      end
    end

    # For WOS-record that has a PMID, fetch data from PubMed and enhance the pub.pub_hash with PubMed data
    # @param [WebOfScience::Record] record
    # @param [Publication] pub
    # @return [void]
    def pubmed_addition(record, pub)
      pubmed_record = PubmedSourceRecord.for_pmid(record.pmid)
      if pubmed_record.nil?
        pubmed_missing(record, pub)
      else
        pub.pub_hash.reverse_update(pubmed_record.source_as_hash)
        pub.save
      end
    rescue StandardError => err
      message = "#{record.uid}, PubmedSourceRecord failed, PMID: #{record.pmid}"
      NotificationManager.error(err, message, self)
    end

    # For WOS-record that has a PMID, cleanup our data when it does not exist on PubMed
    # @param [WebOfScience::Record] record
    # @param [Publication] pub
    # @return [void]
    def pubmed_missing(record, pub)
      WebOfScience.logger.warn "#{record.uid}, PubmedSourceRecord missing, PMID: #{record.pmid}"
      # TODO: find and remove the PublicationIdentifier first
      pub.pmid = nil
      pub.save
    end

  end
end
