require 'forwardable'

module WebOfScience

  # Immutable Web of Knowledge (WOK) identifiers
  class Identifiers
    extend Forwardable
    include Enumerable

    # Delegate enumerable methods to the mutable Hash.
    # This is just a convenience.
    delegate %i(each keys values has_key? has_value? include? reject select to_json) => :to_h

    # @return [String]
    attr_reader :uid

    # @param rec [WebOfScience::Record]
    def initialize(rec)
      raise(ArgumentError, 'ids must be a WebOfScience::Record') unless rec.is_a? WebOfScience::Record
      extract_ids(rec)
      parse_medline
      parse_wos
      @ids.freeze
    end

    # Extract the {DB_PREFIX} from a WOS-UID in the form {DB_PREFIX}:{ITEM_ID}
    # @return [String|nil]
    def database
      @database ||= begin
        uid_split = uid.split(':')
        uid_split.length > 1 ? uid_split[0] : nil
      end
    end

    # @return [String|nil]
    def doi
      ids['doi']
    end

    # @return [String|nil]
    def issn
      ids['issn']
    end

    # Update identifiers to preserve the values already in the identifiers;
    # the update only allows select identifiers to be merged (doi, issn, pmid)
    # an only if those identifiers are not already defined.
    # @param links [Hash<String => String>] other identifiers (from Links API)
    # @return [WebOfScience::Identifiers]
    def update(links)
      return self if links.blank?
      links = filter_ids(links)
      @ids = ids.reverse_merge(links).freeze
      self
    end

    # @return [String|nil]
    def pmid
      ids['pmid']
    end

    # A mutable Hash of the identifiers
    # @return [Hash]
    def to_h
      ids.dup
    end

    # @return [String|nil]
    def wos_item_id
      ids['WosItemID']
    end

    private

      attr_reader :ids

      ALLOWED_TYPES = %w(doi issn pmid).freeze

      # @param ids [Hash]
      def filter_ids(ids)
        ids.select { |type, _v| ALLOWED_TYPES.include? type }
      end

      # @param rec [WebOfScience::Record]
      def extract_ids(rec)
        ids = rec.doc.xpath('/REC/dynamic_data/cluster_related/identifiers/identifier')
        ids = ids.map { |id| [id['type'], id['value']] }.to_h
        @ids = filter_ids(ids)
        @uid = rec.doc.xpath('/REC/UID').text.freeze
        @ids.update('WosUID' => uid)
      end

      def parse_medline
        return unless database == 'MEDLINE'
        ids['pmid'].sub!('MEDLINE:', '') if ids['pmid'].present?
        ids['pmid'] ||= uid.sub('MEDLINE:', '')
      end

      def parse_wos
        return unless database == 'WOS'
        @ids.update('WosItemID' => uid.split(':').last)
      end
  end
end
