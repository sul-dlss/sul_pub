module WebOfScience
  # This class complements the WebOfScience::Harvester
  # Process a WebOfScienceSourceRecord
  # - create a new Publication, PublicationIdentifier(s) and Contribution.
  class ProcessRecord
    include WebOfScience::Contributions
    include WebOfScience::ProcessPubmed

    # @param [Author] author
    # @param [WebOfScienceSourceRecord] src_record
    def initialize(author, src_record)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'src_record must be a WebOfScienceSourceRecord') unless src_record.is_a? WebOfScienceSourceRecord
      @author = author
      @record = src_record.record # use the WebOfScience::Record that wraps the src data
    end

    # @return [void]
    def execute
      return if found_contribution?(author, record)
      pub = create_publication
      find_or_create_contribution(author, pub)
      pubmed_addition(pub) if pub.pmid && record.database != 'MEDLINE'
    rescue StandardError => err
      message = "Author: #{author.id}, ProcessRecord failed #{record.uid}"
      NotificationManager.error(err, message, self)
    end

    private

      attr_reader :author
      attr_reader :record

      # @return [Publication]
      def create_publication
        attr = {
          active: true,
          pub_hash: record.pub_hash,
          wos_uid: record.uid,
          pubhash_needs_update: true
        }
        attr[:pmid] = record.pmid if record.pmid.present?
        Publication.create!(attr)
      end
  end
end
