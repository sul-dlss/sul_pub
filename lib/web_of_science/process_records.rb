module WebOfScience

  # This class complements the WebOfScience::Harvester
  # Process records retrieved by any means; this is a progressive filtering of the harvested records to identify
  # those records that should create a new Publication.pub_hash, PublicationIdentifier(s) and Contribution(s).
  class ProcessRecords
    delegate :logger, to: :WebOfScience

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
      # TODO: batch harvest PubMed data for WOS records with a PMID?
    rescue StandardError => err
      logger.error(err.inspect)
      []
    end

    private

      attr_reader :author
      attr_reader :records

      # ----
      # Record filters and data flow steps

      # @return [Array<String>] WosUIDs that create a new Publication
      def create_publications
        new_wos_records = select_new_wos_records(filter_databases) # cf. WebOfScienceSourceRecord
        saved_wos_records = save_wos_records(new_wos_records) # save WebOfScienceSourceRecord
        new_publications = filter_by_identifiers(saved_wos_records) # cf. PublicationIdentifier
        new_publications.map { |rec| create_publication(rec) }.compact
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
        # IMPORTANT: add nothing to PublicationIdentifiers here, or new_records will reject them
        return [] if records.empty?
        # We only want the 'pmid' for "WOS" records ("MEDLINE" records have one already)
        process_links(records.select { |rec| rec.database == 'WOS' })
        records.select do |rec|
          saved = WebOfScienceSourceRecord.new(source_data: rec.to_xml).save!
          # TODO: add all identifiers to src-record, including links-API identifiers
          saved
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

      ## 4
      # @param [WebOfScience::Record] record
      # @return [String, nil] WosUID for a new Publication
      def create_publication(record)
        pub = Publication.new(active: true, pub_hash: record.pub_hash, xml: record.to_xml)
        pubmed_additions(record, pub) if record.pmid
        create_contribution(pub)
        pub.sync_publication_hash_and_db # creates new PublicationIdentifiers
        pub.save
        record.uid
      rescue StandardError => e
        NotificationManager.error(e, "#{record.uid} failed to create Publication", self)
        nil
      end

      # For WOS-record that has a PMID, fetch data from PubMed and enhance the pub.pub_hash with PubMed data
      # @param [WebOfScience::Record] record
      # @param [Publication] pub
      # @return [Publication, nil]
      def pubmed_additions(record, pub)
        # TODO: compare this with private method in Publication.add_any_pubmed_data_to_hash
        pub.pmid = record.pmid
        return pub if record.database == 'MEDLINE'
        pubmed_record = PubmedSourceRecord.for_pmid(record.pmid)
        raise "Failed to create a PubmedSourceRecord for PMID: #{record.uid}, #{record.pmid}" if pubmed_record.nil?
        pub.pub_hash.reverse_update(pubmed_record.source_as_hash)
        pub
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
          visibility: 'private')
        contrib.save
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
      def process_links(records)
        return if records.empty?
        links = links_client.links records.map(&:uid)
        records.each { |rec| rec.identifiers.update links[rec.uid] }
      rescue StandardError => err
        logger.error(err.inspect)
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
