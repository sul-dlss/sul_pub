module WebOfScience
  # Application logic to harvest publications from Web of Science;
  # This is the bridge between the WebOfScience API and the SUL-PUB application.
  # This class is responsible for processing WebOfScience API response data
  # to integrate it into the application data models.
  class Harvester < ::Harvester::Base
    # Harvest all publications for an author from Web of Science
    # @param [Author] author
    # @param [Hash] options
    # @return [Array<String>] WosUIDs that create Publications
    def process_author(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      log_info(author, "processing author #{author.id}")
      query_author = WebOfScience::QueryAuthor.new(author, options)
      if query_author.valid?
        uids_from_query = query_author.uids
        if uids_from_query.size >= Settings.WOS.max_publications_per_author
          NotificationManager.error(StandardError, "#{self.class} - WoS harvest returned more than #{Settings.WOS.max_publications_per_author} for author id #{author.id} and was aborted", self)
          []
        else
          uids = process_uids(author, uids_from_query)
          log_info(author, "processed author #{author.id}: #{uids.count} new publications")
          uids
        end
      else
        []
      end
    rescue StandardError => err
      NotificationManager.error(err, "#{self.class} - WoS harvest failed for author #{author.id}", self)
    end

    # Harvest WOS-UID publications for an author
    # @param author [Author]
    # @param uids [Array<String>] WOS-UID values (not URIs)
    # @return [Array<String>] WosUIDs that create Publications
    def process_uids(author, uids)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      raise(ArgumentError, 'uids must be Enumerable') unless uids.is_a? Enumerable
      log_info(author, "#{uids.count} UIDs for search")
      # TODO: get all the links for the UIDs and modify contribution checks to use all identifiers
      uids -= author_contributions(author, uids)
      log_info(author, "#{uids.count} UIDs without contributions")
      return [] if uids.empty?
      process_records author, queries.retrieve_by_id(uids)
    end

    # For authorship_api, pair author to pub/contrib, fetching WOS record if necessary
    # @param author [Author]
    # @param uid [String] WOS-UID value (not URI)
    # @return [Publication, nil] Publication created or associated with the Author
    def author_uid(author, uid)
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      found_uid = author_contributions(author, [uid]).first ||
                  process_records(author, queries.retrieve_by_id([uid])).first
      return if found_uid.blank?
      Publication.find_by(wos_uid: found_uid)
    end

    private

      delegate :logger, :queries, to: :WebOfScience

      # Find any matching contributions by author and WOS-UID; create a contribution for any
      # existing publication without one for the author in question.
      # @param author [Author]
      # @param uids [Array<String>]
      # @return [Array<String>] uids guaranteed to have matching Publication and Contribution
      def author_contributions(author, uids)
        Publication.where(wos_uid: uids).find_each.map do |pub|
          author.assign_pub(pub)
          pub.wos_uid
        end
      end

      # Process records retrieved by any means
      # @param author [Author]
      # @param retriever [WebOfScience::Retriever]
      # @return [Array<String>] WosUIDs that create Publications
      def process_records(author, retriever)
        uids = []
        uids += WebOfScience::ProcessRecords.new(author, retriever.next_batch).execute while retriever.next_batch?
        uids.flatten.compact
      end
  end
end
