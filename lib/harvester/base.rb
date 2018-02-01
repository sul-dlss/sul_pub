module Harvester
  # An iota of abstraction for things a harvester must do.
  # The starting point is always one or more Authors.
  class Base
    # @param [Hash] options
    # @return [void]
    def harvest_all(options = {})
      total = authors_query.count
      count = 0
      authors_query.find_in_batches(batch_size: batch_size).each do |batch|
        harvest(batch, options)
        count += batch_size
        logger.info "completed #{count} of #{total} authors for harvest"
      end
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
