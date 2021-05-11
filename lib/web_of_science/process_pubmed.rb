# frozen_string_literal: true

require 'identifiers'

module WebOfScience
  # Used in the Web of Science harvesting process
  module ProcessPubmed
    # For WOS-records with a PMID, try to enhance them with PubMed data
    # @param [Array<WebOfScience::Record>] records
    def pubmed_additions(records)
      raise(ArgumentError, 'records must be Enumerable') unless records.is_a? Enumerable
      raise(ArgumentError, 'records must contain WebOfScience::Record') unless records.all? do |rec|
                                                                                 rec.is_a? WebOfScience::Record
                                                                               end

      present_recs = records.select { |record| record.pmid.present? }
      uid_to_pub = Publication.where(wos_uid: present_recs.map(&:uid)).group_by(&:wos_uid)
      present_recs.each do |record|
        next if uid_to_pub[record.uid].blank?

        pub = uid_to_pub[record.uid].first
        pmid = parse_pmid(record.pmid) # validate a PMID before saving it to a Publication
        pub.pmid.nil? || next # first PMID is enough
        pub.pmid = pmid
        pub.save!
        pubmed_addition(pub) if record.database != 'MEDLINE'
      rescue StandardError => e
        message = "#{record.uid}, pubmed_additions for pmid '#{record.pmid}' failed"
        NotificationManager.error(e, message, self)
      end
    rescue StandardError => e
      NotificationManager.error(e, 'pubmed_additions failed', self)
    end

    # For WOS-record that has a PMID, fetch data from PubMed and enhance the pub.pub_hash with PubMed data
    # but don't do anything if pubmed looksups are disabled.
    # @param [Publication] pub is a Publication with a .pmid value
    # @return [void]
    def pubmed_addition(pub)
      raise(ArgumentError, 'pub must be Publication') unless pub.is_a? Publication
      return unless Settings.PUBMED.lookup_enabled

      pmid = parse_pmid(pub.pmid) # ensure the Publication has a valid PMID
      pubmed_record = PubmedSourceRecord.for_pmid(pmid)
      if pubmed_record.nil?
        pubmed_cleanup(pub, pmid)
        return
      end
      pubmed_hash = pubmed_record.source_as_hash
      pmc_id = pubmed_hash[:identifier].detect { |id| id[:type] == 'pmc' }
      pub.pub_hash.reverse_update(pubmed_hash)
      pub.pub_hash[:identifier] << pmc_id if pmc_id && !pub.pub_hash[:identifier].include?(pmc_id)
      return unless pub.changed?

      pub.pubhash_needs_update!
      pub.save!
    rescue StandardError => e
      NotificationManager.error(e, "pubmed_addition failed for args: #{pmid}, #{pub}", self)
    end

    # For WOS-record that has a PMID, cleanup our data when it does not exist on PubMed;
    # but don't do anything if the Pubmed::Client is not working.
    # @param [Publication] pub is a Publication with a .pmid value
    # @param [Sring] pmid already parsed pmid, if available
    # @return [void]
    def pubmed_cleanup(pub, pmid = nil)
      raise(ArgumentError, 'pub must be Publication') unless pub.is_a? Publication

      pmid ||= parse_pmid(pub.pmid)
      return unless Pubmed.working?

      pub_id = pub.publication_identifiers.find_by(identifier_type: 'PMID', identifier_value: pmid)
      if pub_id.present?
        pub_id.pub_hash_update(delete: true)
        pub_id.destroy
      end
      pub.pmid = nil
      pub.pubhash_needs_update!
      pub.save!
    rescue StandardError => e
      NotificationManager.error(e, "pubmed_cleanup failed for args: #{pmid}, #{pub}", self)
    end

    # @param [String, Integer] pmid
    # @return [String] pmid
    # @raise ArgumentError if pmid is not valid
    def parse_pmid(pmid)
      # NOTE: Identifiers::PubmedId.extract(pmid).first returns nil or a String for (String | Integer) arg
      pmid = ::Identifiers::PubmedId.extract(pmid).first
      raise(ArgumentError, 'pmid is not valid') unless pmid.is_a? String

      pmid
    end
  end
end
