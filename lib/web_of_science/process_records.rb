module WebOfScience

  # This class complements the WebOfScience::Harvester
  # Process records retrieved by any means; this is a progressive filtering of the harvested records to identify
  # those records that should create a new Publication.pub_hash, PublicationIdentifier(s) and Contribution(s).
  class ProcessRecords
    include WebOfScience::ProcessPubmed

    # @param author [Author]
    # @param records [WebOfScience::Records]
    def initialize(author, records)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'records must be an WebOfScience::Records') unless records.is_a? WebOfScience::Records
      raise 'Nothing to do when Settings.WOS.ACCEPTED_DBS is empty' if Settings.WOS.ACCEPTED_DBS.empty?
      @author = author
      @records = records.select { |rec| Settings.WOS.ACCEPTED_DBS.include? rec.database }
    end

    # @return [Array<String>] WosUIDs that create a new Publication
    def execute
      return [] if records.empty?
      create_publications
    rescue StandardError => err
      NotificationManager.error(err, "Author: #{author.id}, ProcessRecords failed", self)
      []
    end

    private

      attr_reader :author
      attr_reader :records

      delegate :links_client, to: :WebOfScience

      # from the incoming (db-filtered) records
      def uids
        @uids ||= records.map(&:uid)
      end

      # @return [Array<String>] WosUIDs that successfully create a new Publication or Contribution
      def create_publications
        return [] if records.empty?
        matching_uids = Publication.where(wos_uid: records.map(&:uid)).pluck(:wos_uid)
        save_wos_records(records.reject { |rec| matching_uids.include? rec.uid })
        records.select { |rec| !matching_contribution(author, rec) && create_publication(rec) }
               .map(&:uid)
               .uniq
      ensure
        pubmed_additions(records)
      end

      # Save new WebOfScienceSourceRecords.  This method guarantees to all subsequent proecessing
      # that each record in @records now has a WebOfScienceSourceRecord.
      # @return [Array<WebOfScienceSourceRecord>] created records
      def save_wos_records
        return [] if records.empty?
        already_fetched_uids = WebOfScienceSourceRecord.where(uid: uids).pluck(:uid)
        status_to_recs = records.group_by { |rec| already_fetched_uids.include? rec.uid }
        batch = process_links(status_to_recs[false] || []).map do |rec|
          attribs = { source_data: rec.to_xml }
          attribs[:doi] = rec.doi if rec.doi.present?
          attribs[:pmid] = rec.pmid if rec.pmid.present?
          attribs
        end
        WebOfScienceSourceRecord.create!(batch)
      end

      # Also creates Contribution
      # @param [WebOfScience::Record] record
      # @return [Boolean] WebOfScience::Record created a new Publication?
      def create_publication(record)
        contrib = Contribution.new(
          author_id: author.id,
          cap_profile_id: author.cap_profile_id,
          featured: false, status: 'new', visibility: 'private'
        )
        Publication.create!( # autosaves contrib
          active: true,
          pub_hash: record.pub_hash,
          wos_uid: record.uid,
          pubhash_needs_update: true,
          contributions: [contrib]
        )
      rescue StandardError => err
        message = "Author: #{author.id}, #{record.uid}; Publication or Contribution failed"
        NotificationManager.error(err, message, self)
        false
      end

      # WOS Links API methods
      # Integrate a batch of publication identifiers from the Links-API
      #
      # IMPORTANT: add nothing to PublicationIdentifiers here, or new_records will reject them
      # Note: the WebOfScienceSourceRecord is already saved, it could be updated with
      #       additional identifiers if there are fields defined for it.  Otherwise, these
      #       identifiers will get added to PublicationIdentifier after a Publication is created.
      # @param [Array<WebOfScience::Record>] recs
      # @return [Array<WebOfScience::Record>] the same recs
      def process_links(recs)
        links = retrieve_links
        recs.each { |rec| rec.identifiers.update(links[rec.uid]) if rec.database == 'WOS' }
      rescue StandardError => err
        NotificationManager.error(err, "Author: #{author.id}, process_links failed", self)
      end

      # Retrieve a batch of publication identifiers for WOS records from the Links-API
      # @example {"WOS:000288663100014"=>{"pmid"=>"21253920", "doi"=>"10.1007/s12630-011-9462-1"}}
      # @return [Hash<String => Hash<String => String>>]
      def retrieve_links
        links_client.links records.map { |rec| rec.uid if rec.database == 'WOS' }.compact
      rescue StandardError => err
        NotificationManager.error(err, "Author: #{author.id}, retrieve_links failed", self)
      end

      # Does record have a contribution for this author? (based on matching PublicationIdentifiers)
      # Note: must use unique identifiers, don't use ISSN or similar series level identifiers
      # We search for all PubIDs at once instead of serial queries.  No need to hit the same table multiple times.
      # @param [WebOfScience::Record] record
      # @return [::Publication, nil] a matched or newly minted Contribution
      def matching_publication(record)
        Publication.joins(:publication_identifiers).where(
          "publication_identifiers.identifier_value IS NOT NULL AND (
           (publication_identifiers.identifier_type = 'WosUID' AND publication_identifiers.identifier_value = ?) OR
           (publication_identifiers.identifier_type = 'WosItemID' AND publication_identifiers.identifier_value = ?) OR
           (publication_identifiers.identifier_type = 'doi' AND publication_identifiers.identifier_value = ?) OR
           (publication_identifiers.identifier_type = 'pmid' AND publication_identifiers.identifier_value = ?))",
           record.uid, record.wos_item_id, record.doi, record.pmid
        ).order(
          "CASE
            WHEN publication_identifiers.identifier_type = 'WosUID' THEN 0
            WHEN publication_identifiers.identifier_type = 'WosItemID' THEN 1
            WHEN publication_identifiers.identifier_type = 'doi' THEN 2
            WHEN publication_identifiers.identifier_type = 'pmid' THEN 3
           END"
        ).first
      end
  end
end
