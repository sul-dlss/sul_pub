module WebOfScience

  module Services

    module HashMappers

      class AbstractMapper

        def map_abstract_to_hash(record)
          return {} if record.abstracts.empty?
          # Often there is only one abstract; if there is more than one,
          # assume the first abstract is the most useful abstract.
          abstract = record.abstracts.first
          case record.database
          when 'MEDLINE'
            { abstract: abstract }
          else
            { abstract_restricted: abstract }
          end
        end

      end
    end
  end
end


