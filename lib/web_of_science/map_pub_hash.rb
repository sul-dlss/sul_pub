module WebOfScience
  # Map WOS record data into the SUL PubHash data
  class MapPubHash
    attr_reader :pub
    alias pub_hash pub

    # @param rec [WebOfScience::Record]
    def initialize(rec)
      raise(ArgumentError, 'rec must be a WebOfScience::Record') unless rec.is_a? WebOfScience::Record
      extract(rec)
    end

    private

      # Extract content from record, try not to hang onto the entire record
      # @param rec [WebOfScience::Record]
      def extract(rec)
        @pub = WebOfScience::MapAbstract.new(rec).pub_hash
        pub.update WebOfScience::MapNames.new(rec).pub_hash
        pub.update WebOfScience::MapPublisher.new(rec).pub_hash
        pub.update WebOfScience::MapCitation.new(rec).pub_hash
        pub.update pub_hash_doctypes(rec)
        pub.update pub_hash_identifiers(rec)
        pub.update WebOfScience::MapMesh.new(rec).pub_hash
        pub.update Csl::Citation.new(pub).citations
      end

      # publication document types and categories
      def pub_hash_doctypes(rec)
        types = [rec.doctypes, rec.pub_info['pubtype']].flatten.compact
        doc = {
          documenttypes_sw: types,
          documentcategory_sw: rec.pub_info['pubtype']
        }
        doc[:type] = if types.any? { |t| t =~ /\b(Meeting|Conference|Congresses|Overall|Proceeding)/i }
                       Settings.sul_doc_types.inproceedings
                     else
                       Settings.sul_doc_types.article
                     end
        doc
      end

      # publication identifiers
      def pub_hash_identifiers(rec)
        ids = rec.identifiers
        id = {
          identifier: ids.pub_hash,
          provenance: Settings.wos_source,
          wos_uid: ids.uid
        }
        id[:doi] = ids.doi if ids.doi.present?
        id[:eissn] = ids.eissn if ids.eissn.present?
        id[:issn] = ids.issn if ids.issn.present?
        id[:pmid] = ids.pmid if ids.pmid.present?
        id[:wos_item_id] = ids.wos_item_id if ids.wos_item_id.present?
        id
      end
  end
end
