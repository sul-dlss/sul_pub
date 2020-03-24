module Harvester
  # An iota of abstraction for things a harvester must do.
  # The starting point is always one or more Authors.

  # Exception for reporting issues that occur during harvesting
  class Error < StandardError; end

  class Base
    # @param [Hash] options
    # @return [void]
    def harvest_all(options = {})
      total = authors_query.count
      count = 0
      start_time = Time.zone.now
      logger.info "***** Started a complete harvest for #{total} authors at #{start_time}"
      authors_query.find_in_batches(batch_size: batch_size).each_with_index do |batch, n|
        harvest(batch, options)
        count += batch.size
        logger.info "*** Completed batch #{n} with #{batch.size} authors.  On #{count} of #{total} authors for harvest at #{Time.zone.now}.  Start time was #{start_time}."
      end
      end_time = Time.zone.now
      time_taken = Time.at(end_time - start_time).utc.strftime "%e days, %H hours, %M minutes"
      logger.info "***** Ended a complete harvest for #{total} authors at #{end_time}.  Time taken: #{time_taken}"
    end

    # @param [Enumerable<Author>] authors
    # @param [Hash] options
    # @return [void]
    def harvest(authors, options = {})
      count = authors.count
      logger.info("#{self.class} - started harvest - #{count} authors - #{options}")
      author_success = 0
      authors.each do |author|
        process_author(author, options)
        author.harvested = true
        author_success += 1
      end
      logger.info("#{self.class} - completed harvest - #{author_success} of #{count} processed")
    rescue StandardError => err
      NotificationManager.error(err, "harvest(authors) failed - #{author_success} of #{count} processed", self)
    end

    # Harvest all publications for an author
    # @param [Author] _author
    # @param [Hash] _options
    # @return [Array<String>] ids that create Publications
    def process_author(_author, _options = {})
      raise "process_author must be implemented in subclass"
    end

    private

      # @return [Integer]
      def batch_size
        50
      end

      # @return [Author::ActiveRecord_Relation]
      # NOTE AR find_in_batches ignores order and limit on the query scope, and this method is used later with find_in_batches
      def authors_query
        @authors_query ||= Author.where(active_in_cap: true, cap_import_enabled: true).order(:id)
      end

      # A default logger - a subclass can override the default
      # @return [Logger]
      def logger
        @logger ||= Rails.logger
      end

      # Consistent log prefix for status updates
      # @param author [Author]
      # @param [String] message
      # @return [void]
      def log_info(author, message)
        prefix = self.class.to_s
        prefix += " - author #{author.id}" if author.is_a?(Author)
        logger.info "#{prefix} - #{message}"
      end
  end
end
