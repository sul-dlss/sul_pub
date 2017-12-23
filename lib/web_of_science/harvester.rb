module WebOfScience

  # Application logic to harvest publications from Web of Science;
  # This is the bridge between the WebOfScience API and the SUL-PUB application.
  # This class is responsible for processing WebOfScience API response data
  # to integrate it into the application data models.
  class Harvester < ::Harvester::Base
    delegate :logger, to: :WebOfScience

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
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      logger.info "#{self.class} - processing author: #{author.id}"
      uids = process_records author, records_for_author(author)
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
      dois.reject! { |doi| publication_identifier?('doi', doi) }
      return [] if dois.empty?
      records = wos_queries.search_by_doi(dois.shift)
      dois.each { |doi| records.merge_records wos_queries.search_by_doi(doi) }
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
      pmids.reject! { |pmid| publication_identifier?('pmid', pmid) }
      return [] if pmids.empty?
      process_records author, wos_queries.retrieve_by_pmid(pmids)
    end

    # Harvest WOS-UID publications for an author
    # @param author [Author]
    # @param uids [Array<String>] WOS-UID or WOS-ItemId values (not URIs)
    # @return [Array<String>] WosUIDs that create Publications
    def process_uids(author, uids)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'uids must be Enumerable') unless uids.is_a? Enumerable
      uids.reject! { |uid| publication_identifier?('WosItemId', wos_item(uid)) }
      return [] if uids.empty?
      process_records author, wos_queries.retrieve_by_id(uids)
    end

    private

      # Process records retrieved by any means
      # @param author [Author]
      # @param records [WebOfScience::Records]
      # @return [Array<String>] WosUIDs that create Publications
      def process_records(author, records)
        processor = WebOfScience::ProcessRecords.new(author, records)
        processor.execute
      end

      # ----
      # Retrieve WOS Records for Author

      # @param author [Author]
      # @return [WebOfScience::Records]
      def records_for_author(author)
        # TODO: iterate on author identities also, or leave that to the consumer of this class?
        names = author_name(author).text_search_query
        institution = author_institution(author).normalize_name
        user_query = "AU=(#{names}) AND AD=(#{institution})"
        query = wos_queries.params_for_search(user_query)
        wos_queries.search(query)
      end

      # @param author [Author]
      # @return [Agent::AuthorName]
      def author_name(author)
        Agent::AuthorName.new(
          author.last_name,
          author.first_name,
          Settings.HARVESTER.USE_MIDDLE_NAME ? author.middle_name : ''
        )
      end

      # @param author [Author]
      # @return [Agent::AuthorInstitution]
      def author_institution(author)
        return default_institution if author.institution.blank?
        Agent::AuthorInstitution.new(author.institution)
      end

      # @return [Agent::AuthorInstitution]
      def default_institution
        @default_institution ||= begin
          Agent::AuthorInstitution.new(
            Settings.HARVESTER.INSTITUTION.name,
            Agent::AuthorAddress.new(Settings.HARVESTER.INSTITUTION.address.to_hash)
          )
        end
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

      # Extract a WOS-ItemId from a WOS-UID or a WosItemId
      # - a WOS-UID has the form {DB_PREFIX}:{WOS_ITEM_ID}
      # - a WOS-ItemId has no {DB_PREFIX}:
      # @param id [String]
      # @return [String] the {WOS_ITEM_ID}
      def wos_item(id)
        id.split(':').last
      end

      # @return [WebOfScience::Queries]
      def wos_queries
        WebOfScience.queries
      end
  end
end
