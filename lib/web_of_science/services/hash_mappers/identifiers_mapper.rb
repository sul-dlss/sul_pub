require 'forwardable'

module WebOfScience

  module Services

    module HashMappers

      class IdentifiersMapper

        def map_identifiers_to_hash(rec)
          pub = {}
          pub[:provenance] = Settings.wos_source
          pub[:doi] = rec.doi if rec.doi.present?
          pub[:eissn] = rec.eissn if rec.eissn.present?
          pub[:issn] = rec.issn if rec.issn.present?
          pub[:pmid] = rec.pmid if rec.pmid.present?
          pub[:wos_uid] = rec.uid
          pub[:wos_item_id] = rec.wos_item_id if rec.wos_item_id.present?
          pub[:identifier] = rec.identifiers.pub_hash
          pub
        end

      end
    end
  end
end
