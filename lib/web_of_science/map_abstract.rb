module WebOfScience

  # Map WOS record abstract data into the SUL PubHash data
  class MapAbstract < Mapper

    # @return [Array<String>]
    def abstracts
      # Note: rec.doc.xpath(nil).map(&:text) => []
      @abstracts ||= rec.doc.xpath(path).map(&:text)
    end

    private

      # publication abstract details
      # @return [Hash]
      def mapper
        return {} if abstracts.empty?
        @abstract ||= begin
          # Often there is only one abstract; if there is more than one,
          # assume the first abstract is the most useful abstract.
          abstract = abstracts.first
          case rec.database
          when 'MEDLINE'
            { abstract: abstract }
          else
            { abstract_restricted: abstract }
          end
        end
      end

      # The XPath for abstracts data from any WOK database record
      # @return [String, nil]
      def path
        case rec.database
        when 'MEDLINE', 'WOS'
          '/REC/static_data/fullrecord_metadata/abstracts/abstract/abstract_text'
        else
          rec.logger.error("Unknown WOK database: #{rec.database}")
          nil
        end
      end

  end
end
