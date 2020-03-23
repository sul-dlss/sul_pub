module Pubmed
  # Application logic to harvest publications from Pubmed;
  # This is the bridge between the Pubmed API and the SUL-PUB application.
  # This class is responsible for processing Pubmed API response data
  # to integrate it into the application data models.
  class Harvester < ::Harvester::Base
    # Harvest all publications for an author from Pubmed
    # @param [Author] author
    # @param [Hash] _options
    # @return [Array<String>] pmids that create Publications
    def process_author(author, options = {})
      return unless Settings.PUBMED.harvest_enabled
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      log_info(author, "processing author #{author.id}")
      query_author = Pubmed::QueryAuthor.new(author, options)
      if query_author.valid?
        pmids_from_query = query_author.pmids
        if pmids_from_query.size >= Settings.PUBMED.max_publications_per_author
          NotificationManager.error(StandardError, "#{self.class} - Pubmed harvest returned more than #{Settings.PUBMED.max_publications_per_author} for author id #{author.id} and was aborted", self)
          []
        else
          pmids = process_pmids(author, pmids_from_query)
          log_info(author, "processed author #{author.id}: #{pmids.count} new publications")
          pmids
        end
      else
        NotificationManager.error(StandardError, "#{self.class} - An invalid author query was detected for author id #{author.id} and was aborted", self)
        []
      end
    rescue StandardError => err
      NotificationManager.error(err, "#{self.class} - Pubmed harvest failed for author #{author.id}", self)
    end

    private

      delegate :logger, :client, to: :Pubmed

      # Harvest Pubmed publications for an author
      # @param author [Author]
      # @param pmids [Array<String>] PubMed ids
      # @return [Array<String>] pmids that create Publications
      def process_pmids(author, pmids)
        raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
        raise(ArgumentError, 'uids must be Enumerable') unless pmids.is_a? Enumerable
        log_info(author, "#{pmids.count} pmids for search")
        # Remove pmids that already exist, making sure author is assigned.
        pmids -= author_contributions(author, pmids)
        log_info(author, "#{pmids.count} pmids without existing contributions")
        pmids.each { |pmid| process_pmid author, pmid }
        pmids
      end

      # Find any matching contributions by author and pmid; create a contribution for any
      # existing publication without one for the author in question.
      # @param author [Author]
      # @param pmids [Array<String>]
      # @return [Array<String>] pmids guaranteed to have matching Publication and Contribution
      def author_contributions(author, pmids)
        matched = []
        pmids.each do |pmid|
          pub = Publication.find_by_pmid_pub_id(pmid)
          next unless pub

          author.assign_pub(pub)
          matched << pmid
        end
        matched
      end

      # Process a pubmed records
      # @param author [Author]
      # @param pmid [String]
      def process_pmid(author, pmid)
        pub = PubmedSourceRecord.get_pub_by_pmid(pmid)
        # Make sure author is assigned
        author.assign_pub(pub)
      end
  end
end
