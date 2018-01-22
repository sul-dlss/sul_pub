module Harvester
  # An iota of abstraction for things a harvester must do.
  # The starting point is always one or more Authors.
  class Base
    # @return [void]
    def harvest_all
      Author.where(active_in_cap: true, cap_import_enabled: true)
            .find_in_batches(batch_size: batch_size)
            .each { |batch| harvest(batch) }
    end

    # @param [Enumerable<Author>] _authors
    # @return [void]
    def harvest(_authors)
      raise "harvest must be implemented in subclass"
    end

    private

      def batch_size
        50
      end
  end
end
