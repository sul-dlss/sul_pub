
module WebOfScience
  module Services
    module HashMappers
      class DocTypeMapper

        def map_doc_type_to_hash(record)
          pub   = {}
          types = [record.doctypes, record.pub_info['pubtype']].flatten.compact

          pub[:documenttypes_sw]    = types
          pub[:documentcategory_sw] = record.pub_info['pubtype']
          pub[:type]                = case record.pub_info['pubtype']
                                      when /conference/i
                                        Settings.sul_doc_types.inproceedings
                                      else
                                        Settings.sul_doc_types.article
                                      end
          pub
        end

      end
    end
  end
end

