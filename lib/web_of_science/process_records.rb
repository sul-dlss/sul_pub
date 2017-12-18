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
      @records = records
    end

    # @return [Array<String>] WosUIDs that create a new Publication
    def execute
      return [] if records.count.zero?
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
        new_records = select_new_wos_records(filter_databases) # cf. WebOfScienceSourceRecord
        new_records = save_wos_records(new_records) # save WebOfScienceSourceRecord
        new_records = filter_by_identifiers(new_records) # cf. PublicationIdentifier
        new_records = new_records.select { |rec| create_publication(rec) }
        pubmed_additions(new_records)
        new_records.map(&:uid)
      end

      ## 1
      # Filter and select new WebOfScienceSourceRecords
      # @return [Array<WebOfScience::Record>]
      def filter_databases
        return [] if records.count.zero?
        return records if Settings.WOS.ACCEPTED_DBS.empty?
        records.select { |rec| Settings.WOS.ACCEPTED_DBS.include? rec.database }
      end

      ## 2
      # Filter and select new WebOfScienceSourceRecords
      # @return [Array<WebOfScience::Record>]
      def select_new_wos_records(records)
        return [] if records.count.zero?
        matching_uids = WebOfScienceSourceRecord.where(uid: records.map(&:uid)).pluck(:uid)
        records.reject { |rec| matching_uids.include? rec.uid }
      end

      ## 3
      # Save and select new WebOfScienceSourceRecords
      # @param [Array<WebOfScience::Record>] records
      # @return [Array<WebOfScience::Record>]
      def save_wos_records(records)
        # IMPORTANT: add nothing to PublicationIdentifiers here, or filter_by_identifiers will reject them
        return [] if records.empty?
        # We only want the 'pmid' for "WOS" records ("MEDLINE" records have one already)
        process_links(records.select { |rec| rec.database == 'WOS' })
        records.select do |rec|
          attr = { source_data: rec.to_xml }
          attr[:doi] = rec.doi if rec.doi.present?
          attr[:pmid] = rec.pmid if rec.pmid.present?
          WebOfScienceSourceRecord.new(attr).save!
        end
      end

      ## 4
      # Select records that have no matching PublicationIdentifiers
      # @param [Array<WebOfScience::Record>] records
      # @return [Array<WebOfScience::Record>]
      def filter_by_identifiers(records)
        return [] if records.empty?
        records.reject do |rec|
          publication_identifier?('WosItemID', rec.wos_item_id) ||
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
          xml: record.to_xml,
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
      # @param [Array<WebOfScience::Record>] records
      # @return [void]
      def pubmed_additions(records)
        records.select { |rec| rec.pmid.present? }.each { |rec| pubmed_addition(rec) }
      end

      # For WOS-record that has a PMID, fetch data from PubMed and enhance the pub.pub_hash with PubMed data
      # @param [WebOfScience::Record] record
      # @return [void]
      def pubmed_addition(record)
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
      # @param records [Array<WebOfScience::Record>]
      # @return [void]
      def process_links(records)
        return if records.empty?
        links = links_client.links records.map(&:uid)
        records.each { |rec| process_link(rec, links[rec.uid]) }
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
