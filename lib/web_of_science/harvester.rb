module WebOfScience

  # Application logic to harvest publications from Web of Science;
  # This is the bridge between the WebOfScience API and the SUL-PUB application.
  # This class is responsible for processing WebOfScience API response data
  # to integrate it into the application data models.
  class Harvester < ::Harvester::Base
    include WebOfScience::Contributions

    # @param [Enumerable<Author>] authors
    # @return [void]
    def harvest(authors)
      logger.info "#{self.class} - started harvest(authors) - #{authors.count} authors"
      author_success = 0
      authors.each do |author|
        process_author(author)
        author_success += 1
      end
      logger.info "#{self.class} - completed harvest(authors) - #{author_success} processed"
    rescue StandardError => err
      message = "#{self.class} - harvest(authors) failed - #{author_success} processed"
      NotificationManager.error(err, message, self)
    end

    # Harvest all publications for an author
    # @param author [Author]
    # @return [Array<String>] WosUIDs that create Publications
    def process_author(author)
      # TODO: iterate on author identities also, or leave that to the consumer of this class?
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      logger.info "#{self.class} - processing author: #{author.id}"
      uids = WebOfScience::QueryAuthor.new(author).uids
      logger.info "#{self.class} - #{uids.count} found by author query"
      uids = process_uids(author, uids)
      logger.info "#{self.class} - #{uids.count} new publications"
      logger.info "#{self.class} - processed author: #{author.id}"
      uids
    rescue StandardError => err
      message = "#{self.class} - harvest failed for author"
      NotificationManager.error(err, message, self)
    end

    # Harvest DOI publications for an author
    # @param author [Author]
    # @param dois [Array<String>] DOI values (not URIs)
    # @return [Array<String>] WosUIDs that create Publications
    def process_dois(author, dois)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'dois must be Enumerable') unless dois.is_a? Enumerable
      # TODO: normalize the dois using altmetrics identifier gem, as in PR #246
      dois.reject! { |doi| contribution_by_identifier?(author, 'doi', doi) }
      return [] if dois.empty?
      records = queries.search_by_doi(dois.shift)
      dois.each { |doi| records.merge_records queries.search_by_doi(doi) }
      process_records author, records
    end

    # Harvest PMID publications for an author
    # @param author [Author]
    # @param pmids [Array<String>] PMID values (not URIs)
    # @return [Array<String>] WosUIDs that create Publications
    def process_pmids(author, pmids)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'pmids must be Enumerable') unless pmids.is_a? Enumerable
      # TODO: normalize the pmids using altmetrics identifier gem, as in PR #246
      pmids.reject! { |pmid| contribution_by_identifier?(author, 'pmid', pmid) }
      return [] if pmids.empty?
      process_records author, queries.retrieve_by_pmid(pmids)
    end

    # Harvest WOS-UID publications for an author
    # @param author [Author]
    # @param uids [Array<String>] WOS-UID values (not URIs)
    # @return [Array<String>] WosUIDs that create Publications
    def process_uids(author, uids)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'uids must be Enumerable') unless uids.is_a? Enumerable
      uids -= author_contributions(author, uids)
      return [] if uids.empty?
      process_records author, queries.retrieve_by_id(uids)
    end

    private

      delegate :logger, :queries, to: :WebOfScience

      # Process records retrieved by any means
      # @param author [Author]
      # @param records [WebOfScience::Records]
      # @return [Array<String>] WosUIDs that create Publications
      def process_records(author, records)
        processor = WebOfScience::ProcessRecords.new(author, records)
        processor.execute
      end

  end
end
