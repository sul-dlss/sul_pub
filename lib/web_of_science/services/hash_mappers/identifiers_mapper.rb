require 'forwardable'

module WebOfScience

  module Services

    module HashMappers

      class IdentifiersMapper

        def map_identifiers_to_hash(rec)
          pub = {}
          pub[:provenance] = Settings.wos_source
          pub[:doi] = rec.doi if rec.doi.present?
          pub[:eissn] = rec.identifiers.eissn if rec.identifiers.eissn.present?
          pub[:issn] = rec.identifiers.issn if rec.identifiers.issn.present?
          pub[:pmid] = rec.identifiers.pmid if rec.identifiers.pmid.present?
          pub[:wos_uid] = rec.uid
          pub[:wos_item_id] = rec.wos_item_id if rec.wos_item_id.present?
          pub[:identifier] = rec.identifiers.pub_hash
          pub
        end

      end
    end
  end
end
