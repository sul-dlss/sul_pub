module WebOfScience

  # This class complements the WebOfScience::Harvester
  class ProcessRecords

    # @param author [Author]
    # @param records [Enumerable<WebOfScience::Record>]
    # @param options [Hash]
    def initialize(author, records, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'records must be an Enumerable') unless records.is_a? Enumerable
      raise 'Nothing to do when Settings.WOS.ACCEPTED_DBS is empty' if Settings.WOS.ACCEPTED_DBS.empty?
      @author = author
      @records = records.select { |rec| Settings.WOS.ACCEPTED_DBS.include? rec.database }
      @options = { delayed: false }.merge options
    end

    # @return [void]
    def execute
      return [] if records.empty?
      process_records
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
      # - this is a progressive reduction of the number of records processed, given
      #   application logic for the de-duplication of new records.

      # Process records retrieved by any means
      def process_records
        WebOfScience::ProcessLinks.process_links(records)
        records.each { |record| process_record(record) }
      end

      # Process a record retrieved by any means
      # - find or create a new WebOfScienceSourceRecord
      # - initiate a background job to further process a WebOfScienceSourceRecord
      # TODO: detect when to update a record if their sha1 signatures differ
      # @param [WebOfScience::Record] record
      # @return [void]
      def process_record(record)
        src_record = record.source_record_find_or_create
        if options[:delayed]
          WebOfScience::AuthorRecordJob.perform_later(author, src_record) if src_record
        else
          WebOfScience::ProcessRecord.new(author, src_record).execute
        end
      rescue StandardError => err
        NotificationManager.error(err, "#{self.class} - failed to find or create record", self)
      end
  end
end
