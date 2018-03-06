module WebOfScience

  # This class complements the WebOfScience::Harvester
  class ProcessRecord
    include WebOfScience::Contributions

    # @param [Author] author
    # @param [WebOfScience::Record] record
    # @param [Hash] links identifiers for this record
    def initialize(author, record, links = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      @author = author
      @record = check_record(record, links)
    end

    # @return [String, nil] WosUID when it results in a new Publication
    def execute
      process_record
    rescue StandardError => err
      message = "Author: #{author.id}, ProcessRecord failed #{record.uid}"
      NotificationManager.error(err, message, self)
      nil
    end

    private

      attr_reader :author
      attr_reader :record

      # @param [WebOfScience::Record] record
      # @param [Hash] links identifiers
      # @return [WebOfScience::Record]
      def check_record(record, links)
        raise(ArgumentError, 'record must be an WebOfScience::Record') unless record.is_a? WebOfScience::Record
        check_settings(record)
        record.identifiers.update(links) if links.present?
        record
      end

      # @param [WebOfScience::Record] record
      # @return [void]
      def check_settings(record)
        raise 'Settings.WOS.ACCEPTED_DBS is empty' if Settings.WOS.ACCEPTED_DBS.empty?
        raise "Settings.WOS.ACCEPTED_DBS rejected #{record.uid}" unless Settings.WOS.ACCEPTED_DBS.include?(record.database)
      end

      # Process a record retrieved by any means; this is a progressive filtering of the record to identify
      # whether it should create a new Publication.pub_hash, PublicationIdentifier(s) and Contribution(s).
      # @return [String, nil] WosUID that create a new Publication
      def process_record
        save_record # as WebOfScienceSourceRecord
        return if matching_contribution(author, record)
        contrib_persisted = create_publication
        pubmed_addition
        record.uid if contrib_persisted
      end

      # Save a new WebOfScienceSourceRecord
      # Note: add nothing to PublicationIdentifiers here, or matching_contribution could skip processing this record
      def save_record
        return unless WebOfScienceSourceRecord.find_by(uid: record.uid).nil?
        attr = { source_data: record.to_xml }
        attr[:doi] = record.doi if record.doi.present?
        attr[:pmid] = record.pmid if record.pmid.present?
        WebOfScienceSourceRecord.create!(attr)
      end

      # @return [Boolean] WebOfScience::Record created a new Publication?
      def create_publication
        pub = Publication.create!(
          active: true,
          pub_hash: record.pub_hash,
          wos_uid: record.uid
        )
        contrib = find_or_create_contribution(author, pub)
        contrib.persisted?
      rescue StandardError => err
        message = "Author: #{author.id}, #{record.uid}; Publication or Contribution failed"
        NotificationManager.error(err, message, self)
        false
      end

      # For WOS-record that has a PMID, fetch data from PubMed and enhance the pub.pub_hash with PubMed data
      # @return [void]
      def pubmed_addition
        return if record.pmid.blank?
        pub = Publication.find_by(wos_uid: record.uid)
        pub.pmid = record.pmid
        pub.save
        return if record.database == 'MEDLINE'
        pubmed_record = PubmedSourceRecord.for_pmid(record.pmid)
        pubmed_hash = pubmed_record.source_as_hash
        pub.pub_hash.reverse_update(pubmed_hash)
        pmc_id = pubmed_hash[:identifier].detect { |id| id[:type] == 'pmc' }
        pub.pub_hash[:identifier] << pmc_id if pmc_id
        pub.pubhash_needs_update!
        pub.save
      rescue StandardError => err
        message = "Author: #{author.id}, #{record.uid}, PubmedSourceRecord failed, PMID: #{record.pmid}"
        NotificationManager.error(err, message, self)
      end
  end
end
