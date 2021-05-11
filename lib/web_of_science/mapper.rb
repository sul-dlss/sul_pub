module WebOfScience
  # Map WOS record data into the SUL Publication.pub_hash data
  class Mapper
    delegate :logger, to: :WebOfScience

    # @param rec [WebOfScience::Record]
    def initialize(rec)
      raise(ArgumentError, 'rec must be a WebOfScience::Record') unless rec.is_a? WebOfScience::Record

      extract(rec)
    end

    # Transform mapper content into pub_hash
    # @return [Hash]
    def pub_hash
      # subclasses can map data, otherwise this method should never get called
      raise(NotImplementedError, 'Move along, this is not the mapper your looking for.')
    end

    private

    attr_reader :uid, :database

    # Extract content from record, try not to hang onto the entire record
    # @param rec [WebOfScience::Record]
    def extract(rec)
      @uid = rec.uid
      @database = rec.database
    end
  end
end
