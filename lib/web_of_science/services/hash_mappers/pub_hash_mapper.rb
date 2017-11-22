
module WebOfScience

  module Services

    class PubHashMapper

      def initialize(abstract_mapper, names_mapper, citation_mapper, identifiers_mapper, publishers_mapper)

        @abstract_mapper     = abstract_mapper
        @names_mapper        = names_mapper
        @citation_mapper     = citation_mapper
        @identifiers_mapper  = identifiers_mapper
        @publishers_mapper   = publishers_mapper

      end

      def map_pubication(record)

      end

    end

  end


end
