module Harvester
  # An iota of abstraction for things a harvester must do.
  # The starting point is always one or more Authors.
  class Base
    # @param [Hash] options
    # @return [void]
    def harvest_all(options = {})
      total = authors_query.count
      count = 0
      n = 0
      start_time = Time.zone.now
      logger.info "***** Started a complete harvest for #{total} authors at #{start_time}"
      authors_query.find_in_batches(batch_size: batch_size).each do |batch|
        harvest(batch, options)
        count += batch.size
        n += 1
        logger.info "*** Completed batch #{n} with #{batch.size} authors.  On #{count} of #{total} authors for harvest at #{Time.zone.now}.  Start time was #{start_time}."
      end
      end_time = Time.zone.now
      time_taken = Time.at(end_time - start_time).utc.strftime "%e days, %H hours, %M minutes"
      logger.info "***** Ended a complete harvest for #{total} authors at #{end_time}.  Time taken: #{time_taken}"
    end

    # @param [Enumerable<Author>] _authors
    # @param [Hash] _options
    # @return [void]
    def harvest(_authors, _options = {})
      raise "harvest must be implemented in subclass"
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
  end
end
