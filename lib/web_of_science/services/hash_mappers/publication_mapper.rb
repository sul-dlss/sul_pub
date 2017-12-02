
module WebOfScience

  module Services

    module HashMappers


    class PublicationMapper

      def initialize(abstract_mapper: WebOfScience::Services::HashMappers::AbstractMapper.new,
                     names_mapper: WebOfScience::Services::HashMappers::NamesMapper.new,
                     citation_mapper: WebOfScience::Services::HashMappers::CitationMapper.new,
                     identifiers_mapper: WebOfScience::Services::HashMappers::IdentifiersMapper.new,
                     publishers_mapper: WebOfScience::Services::HashMappers::PublishersMapper.new,
                     doctype_mapper: WebOfScience::Services::HashMappers::DocTypeMapper.new)

        @abstract_mapper     = abstract_mapper
        @names_mapper        = names_mapper
        @citation_mapper     = citation_mapper
        @identifiers_mapper  = identifiers_mapper
        @publishers_mapper   = publishers_mapper
        @doctype_mapper      = doctype_mapper


      end

      def map_publication_to_hash(record)
        @abstract_mapper.map_abstract_to_hash(record)
                        .merge(@names_mapper.map_names_to_hash(record))
                        .merge(@citation_mapper.map_citation_to_hash(record))
                        .merge(@identifiers_mapper.map_identifiers_to_hash(record))
                        .merge(@publishers_mapper.map_publisher_to_hash(record))
                        .merge(@doctype_mapper.map_doc_type_to_hash(record))
      end

    end

  end
  end
end
