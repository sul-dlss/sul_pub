module WebOfScience
  # Map WOS record abstract data into the SUL PubHash data
  class MapAbstract < Mapper
    attr_reader :abstracts

    # publication abstract details
    # @return [Hash]
    def pub_hash
      return {} if abstracts.empty?

      # Often there is only one abstract; if there is more than one,
      # assume the first abstract is the most useful abstract.
      abstract = abstracts.first.strip
      case database
      when 'MEDLINE'
        { abstract: abstract }
      else
        { abstract_restricted: abstract }
      end
    end

    private

    # Extract content from record, try not to hang onto the entire record
    # @param rec [WebOfScience::Record]
    def extract(rec)
      super(rec)
      @abstracts = rec.doc.xpath(path).map(&:text)
    end

    # The XPath for abstracts data from any WOK database record
    # @return [String, nil]
    def path
      case database
      when 'MEDLINE', 'WOS'
        '/REC/static_data/fullrecord_metadata/abstracts/abstract/abstract_text'
      else
        logger.error("Unknown WOK database: #{database}")
        nil
      end
    end
  end
end
