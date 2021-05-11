module WebOfScience

  # This class complements the WebOfScience::Harvester
  # Process records retrieved by any means.
  #
  # In the simplest case, it creates new instances of:
  #   - WebOfScienceSourceRecord,
  #   - Publication (w/ PublicationIdentifier), and
  #   - Contribution(s).
  # where none existed.
  #
  # When only a matching WebOfScienceSourceRecord record exists already,
  # Publication and Contribution are backfilled.
  #
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
    rescue StandardError => e
      NotificationManager.error(e, "Author: #{author.id}, ProcessRecords failed", self)
      []
    end

    private

      attr_reader :author, :records

      delegate :links_client, to: :WebOfScience

      # from the incoming (db-filtered) records
      def uids
        @uids ||= records.map(&:uid)
      end

      # @return [Array<String>] WosUIDs that successfully create a new Publication
      def create_publications
        return [] if records.empty?
        wssrs = save_wos_records
        wssrs_hash = wssrs.map(&:uid).zip(wssrs).to_h
        new_uids = []
        records.each do |rec|
          pub = rec.matching_publication
          wssr = wssrs_hash[rec.uid]
          if pub
            author.assign_pub(pub)
            next if pub.wos_uid && pub.wos_uid != wssr.uid # pub matches other WSSR (e.g. WOS vs. MEDLINE)
            wssr.link_publication(pub) if wssr.publication.blank?
          else
            create_publication(rec, wssr) && new_uids << rec.uid
          end
        end
        new_uids.uniq
      ensure
        pubmed_additions(records)
      end

      # Save new WebOfScienceSourceRecords.  This method guarantees to all subsequent processing
      # that each WOS uid in @records now has a WebOfScienceSourceRecord.
      # @return [Array<WebOfScienceSourceRecord>] all matching or created records
      def save_wos_records
        return [] if records.empty?
        already_fetched_recs = WebOfScienceSourceRecord.where(uid: uids)
        already_fetched_uids = already_fetched_recs.pluck(:uid)
        unmatched_recs = records.reject { |rec| already_fetched_uids.include? rec.uid }
        process_links(unmatched_recs)
        batch = unmatched_recs.map do |rec|
          attribs = { source_data: rec.to_xml }
          attribs[:doi] = rec.doi if rec.doi.present?
          attribs[:pmid] = rec.pmid if rec.pmid.present?
          attribs
        end
        already_fetched_recs + WebOfScienceSourceRecord.create!(batch)
      end

      # Also creates Contribution and links WebOfScienceSourceRecord
      # @param [WebOfScience::Record] record
      # @param [WebOfScienceSourceRecord] WebOfScienceSourceRecord
      # @return [Boolean] WebOfScience::Record created a new Publication?
      def create_publication(record, wssr)
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
        ) do |pub|
          pub.web_of_science_source_record = wssr if wssr.publication.blank?
        end
      end

      # WOS Links API methods
      # Integrate a batch of publication identifiers from the Links-API
      #
      # IMPORTANT: add nothing to PublicationIdentifiers here, or new_records will reject them
      # Note: the WebOfScienceSourceRecord is already saved, it could be updated with
      #       additional identifiers if there are fields defined for it.  Otherwise, these
      #       identifiers will get added to PublicationIdentifier after a Publication is created.
      # @param [Array<WebOfScience::Record>] recs
      def process_links(recs)
        links = retrieve_links(recs)
        return [] if links.blank?
        recs.each { |rec| rec.identifiers.update(links[rec.uid]) if rec.database == 'WOS' }
      rescue StandardError => e
        NotificationManager.error(e, "Author: #{author.id}, process_links failed", self)
      end

      # Retrieve a batch of publication identifiers for WOS records from the Links-API
      # @return [Hash<String => Hash<String => String>>]
      # @example {"WOS:000288663100014"=>{"pmid"=>"21253920", "doi"=>"10.1007/s12630-011-9462-1"}}
      def retrieve_links(recs)
        link_uids = recs.map { |rec| rec.uid if rec.database == 'WOS' }.compact
        return {} if link_uids.blank?
        links_client.links(link_uids)
      rescue StandardError => e
        NotificationManager.error(e, "Author: #{author.id}, retrieve_links failed", self)
      end

  end
end
