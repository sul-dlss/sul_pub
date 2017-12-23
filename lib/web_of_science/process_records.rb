module WebOfScience

  # This class complements the WebOfScience::Harvester
  # Process records retrieved by any means; this is a progressive filtering of the harvested records to identify
  # those records that should create a new Publication.pub_hash, PublicationIdentifier(s) and Contribution(s).
  class ProcessRecords

    # @param author [Author]
    # @param records [WebOfScience::Records]
    def initialize(author, records)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'records must be an WebOfScience::Records') unless records.is_a? WebOfScience::Records
      @author = author
      @records = records.to_a
    end

    # @return [Array<String>] WosUIDs that create a new Publication
    def execute
      return [] if records.empty?
      create_publications
    rescue StandardError => err
      message = "Author: #{author.id}, ProcessRecords failed"
      NotificationManager.error(err, message, self)
      []
    end

    private

      attr_reader :author
      attr_reader :records

      # ----
      # Record filters and data flow steps

      # @return [Array<String>] WosUIDs that create a new Publication
      def create_publications
        filter_databases # cf. Settings.WOS.ACCEPTED_DBS
        select_new_wos_records # cf. WebOfScienceSourceRecord
        save_wos_records # save WebOfScienceSourceRecord
        filter_by_identifiers # cf. PublicationIdentifier
        records.select! { |rec| create_publication(rec) }
        pubmed_additions
        records.map(&:uid)
      end

      ## 1
      # Filter and select new WebOfScienceSourceRecords
      def filter_databases
        return if records.empty? || Settings.WOS.ACCEPTED_DBS.empty?
        records.select! { |rec| Settings.WOS.ACCEPTED_DBS.include? rec.database }
      end

      ## 2
      # Filter and select new WebOfScienceSourceRecords
      def select_new_wos_records
        return if records.empty?
        matching_uids = WebOfScienceSourceRecord.where(uid: records.map(&:uid)).pluck(:uid)
        records.reject! { |rec| matching_uids.include? rec.uid }
      end

      ## 3
      # Save and select new WebOfScienceSourceRecords
      # IMPORTANT: add nothing to PublicationIdentifiers here, or filter_by_identifiers will reject them
      def save_wos_records
        return if records.empty?
        process_links
        records.select! do |rec|
          attr = { source_data: rec.to_xml }
          attr[:doi] = rec.doi if rec.doi.present?
          attr[:pmid] = rec.pmid if rec.pmid.present?
          WebOfScienceSourceRecord.new(attr).save!
        end
      end

      ## 4
      # Select records that have no matching PublicationIdentifiers
      def filter_by_identifiers
        records.reject! do |rec|
          publication_identifier?('WosUID', rec.uid) ||
            rec.identifiers.any? { |type, value| publication_identifier?(type, value) }
        end
      end

      ## 5
      # @param [WebOfScience::Record] record
      # @return [Boolean] WebOfScience::Record created a new Publication?
      def create_publication(record)
        pub = Publication.new(
          active: true,
          pub_hash: record.pub_hash,
          wos_uid: record.uid
        )
        create_contribution(pub)
        pub.sync_publication_hash_and_db # creates new PublicationIdentifiers
        pub.save!
      rescue StandardError => err
        message = "Author: #{author.id}, #{record.uid}; Publication or Contribution failed"
        NotificationManager.error(err, message, self)
        false
      end

      # Create a Contribution to associate Publication with Author
      # @param [Publication] pub
      def create_contribution(pub)
        # Saving a Contribution also saves pub to assign publication_id and it populates pub.pub_hash[:authorship]
        contrib = pub.contributions.find_or_initialize_by(
          author_id: author.id,
          cap_profile_id: author.cap_profile_id,
          featured: false,
          status: 'new',
          visibility: 'private'
        )
        contrib.save
      end

      # For WOS-records with a PMID, try to enhance them with PubMed data
      def pubmed_additions
        records.each { |rec| pubmed_addition(rec) }
      end

      # For WOS-record that has a PMID, fetch data from PubMed and enhance the pub.pub_hash with PubMed data
      # @param [WebOfScience::Record] record
      # @return [void]
      def pubmed_addition(record)
        return if record.pmid.blank?
        pub = Publication.find_by(wos_uid: record.uid)
        pub.pmid = record.pmid
        pub.save
        return if record.database == 'MEDLINE'
        pubmed_record = PubmedSourceRecord.for_pmid(record.pmid)
        pub.pub_hash.reverse_update(pubmed_record.source_as_hash)
        pub.save
      rescue StandardError => err
        message = "Author: #{author.id}, #{record.uid}, PubmedSourceRecord failed, PMID: #{record.pmid}"
        NotificationManager.error(err, message, self)
      end

      # ----
      # WOS Links API methods

      # Retrieve a batch of publication identifiers from the Links-API
      #
      # IMPORTANT: add nothing to PublicationIdentifiers here, or new_records will reject them
      # Note: the WebOfScienceSourceRecord is already saved, it could be updated with
      #       additional identifiers if there are fields defined for it.  Otherwise, these
      #       identifiers will get added to PublicationIdentifier after a Publication is created.
      #
      # @return [void]
      def process_links
        return if records.empty?
        uids = records.map { |rec| rec.uid if rec.database == 'WOS' }.compact
        links = links_client.links uids
        records.each { |rec| process_link(rec, links[rec.uid]) if rec.database == 'WOS' }
      rescue StandardError => err
        message = "Author: #{author.id}, ProcessLinks failed"
        NotificationManager.error(err, message, self)
      end

      # @param record [WebOfScience::Record]
      # @param links [Hash<String => String>] other identifiers (from Links API)
      # @return [void]
      def process_link(record, links)
        record.identifiers.update links
      rescue StandardError => err
        message = "Author: #{author.id}, #{record.uid}, ProcessLink failed"
        NotificationManager.error(err, message, self)
      end

      # @return [WebOfScience::LinksClient]
      def links_client
        @links_client ||= Clarivate::LinksClient.new
      end

      # ----
      # Utility methods

      # Is there a PublicationIdentifier matching the type and value?
      # @param type [String]
      # @param value [String]
      def publication_identifier?(type, value)
        return false if value.nil?
        PublicationIdentifier.where(identifier_type: type, identifier_value: value).count > 0
      end
  end
end
