module WebOfScience

  # Map WOS record data into the SUL Publication.pub_hash data
  class Mapper

    # @param rec [WebOfScience::Record]
    def initialize(rec)
      raise(ArgumentError, 'rec must be a WebOfScience::Record') unless rec.is_a? WebOfScience::Record
      @rec = rec
    end

    # @return [Hash]
    def pub_hash
      mapper
    end

    private

      attr_reader :rec

      def mapper
        # subclasses can map data, otherwise this method should never get called
        raise(NotImplementedError, 'Move along, this is not the mapper your looking for.')
      end

  end
end
