require 'forwardable'

module WebOfScience

  # Immutable Web of Knowledge (WOK) identifiers
  class Identifiers
    extend Forwardable
    include Enumerable

    # Delegate enumerable methods to the mutable Hash.
    # This is just a convenience.
    delegate %i[each keys values has_key? has_value? include? reject select to_json] => :to_h

    # @return [String]
    attr_reader :uid

    # @param rec [WebOfScience::Record]
    def initialize(rec)
      raise(ArgumentError, 'rec must be a WebOfScience::Record') unless rec.is_a? WebOfScience::Record
      extract_ids rec.doc
      extract_uid rec.doc
      parse_medline rec.doc
      parse_wos
      @ids.freeze
    end

    # Extract the DB_PREFIX from a WOS-UID in the form "DB_PREFIX:ITEM_ID"
    # @return [String, nil]
    def database
      @database ||= begin
        uid_split = uid.split(':')
        uid_split.length > 1 ? uid_split[0] : nil
      end
    end

    # @return [String, nil]
    def doi
      ids['doi']
    end

    # @return [String, nil]
    def doi_uri
      "#{Settings.DOI.BASE_URI}#{doi}" if doi.present?
    end

    # @return [String, nil]
    def eissn
      ids['eissn']
    end

    # @return [String, nil]
    def eissn_uri
      "#{Settings.SULPUB_ID.SEARCHWORKS_URI}#{eissn}" if eissn.present?
    end

    # @return [String, nil]
    def issn
      ids['issn']
    end

    # @return [String, nil]
    def issn_uri
      "#{Settings.SULPUB_ID.SEARCHWORKS_URI}#{issn}" if issn.present?
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

    # @return [String, nil]
    def pmid
      ids['pmid']
    end

    # @return [String, nil]
    def pmid_uri
      "#{Settings.PUBMED.ARTICLE_BASE_URI}#{pmid}" if pmid.present?
    end

    # A mutable Hash of the identifiers
    # @return [Hash<String => String>]
    def to_h
      hash = { 'WosUID' => uid }
      if doi.present?
        hash['doi']     = doi
        hash['doi_uri'] = doi_uri
      end
      if eissn.present?
        hash['eissn']     = eissn
        hash['eissn_uri'] = eissn_uri
      end
      if issn.present?
        hash['issn']     = issn
        hash['issn_uri'] = issn_uri
      end
      if pmid.present?
        hash['pmid']     = pmid
        hash['pmid_uri'] = pmid_uri
      end
      if wos_item_id.present?
        hash['WosItemID']  = wos_item_id
        hash['WosItemURI'] = wos_item_uri
      end
      hash
    end

    # @return [Array<Hash>]
    def pub_hash
      ids = []
      ids << { type: 'doi', id: doi, url: doi_uri } if doi.present?
      ids << { type: 'eissn', id: eissn, url: eissn_uri } if eissn.present?
      ids << { type: 'issn', id: issn, url: issn_uri } if issn.present?
      ids << { type: 'pmid', id: pmid, url: pmid_uri } if pmid.present?
      ids << { type: 'WosItemID', id: wos_item_id, url: wos_item_uri } if wos_item_id.present?
      ids << { type: 'WosUID', id: uid }
      ids
    end

    # @return [String, nil]
    def wos_item_id
      ids['WosItemID']
    end

    # @return [String, nil]
    def wos_item_uri
      "#{Settings.SCIENCEWIRE.ARTICLE_BASE_URI}#{wos_item_id}" if wos_item_id.present?
    end

    private

      attr_reader :ids

      ALLOWED_TYPES = %w[doi eissn issn pmid].freeze

      def extract_ids(doc)
        ids = doc.xpath('/REC/dynamic_data/cluster_related/identifiers/identifier')
        ids = ids.map { |id| [id['type'], id['value']] }.to_h
        ids = filter_dois(ids)
        @ids = filter_ids(ids)
      end

      def extract_uid(doc)
        @uid = doc.xpath('/REC/UID').text.freeze
        ids.update('WosUID' => @uid)
      end

      # Extract an xref_doi as the doi, if the doi is not available and xref_doi is available
      # @param ids [Hash]
      def filter_dois(ids)
        xref_doi = ids['xref_doi']
        ids['doi'] ||= xref_doi if xref_doi.present?
        ids
      end

      # @param ids [Hash]
      def filter_ids(ids)
        ids.select { |type, _v| ALLOWED_TYPES.include? type }
      end

      def parse_medline(doc)
        return unless database == 'MEDLINE'
        parse_medline_issn(doc)
        parse_medline_pmid
      end

      def parse_medline_issn(doc)
        issn = doc.xpath('/REC/static_data/item/MedlineJournalInfo/ISSNLinking')
        ids['issn'] ||= issn.text if issn.present?
      end

      def parse_medline_pmid
        ids['pmid'].sub!('MEDLINE:', '') if ids['pmid'].present?
        ids['pmid'] ||= uid.sub('MEDLINE:', '')
      end

      def parse_wos
        return unless database == 'WOS'
        ids.update('WosItemID' => uid.split(':').last)
      end
  end
end
