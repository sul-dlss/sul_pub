module ScienceWire
  module Query
    class PublicationQueryByAuthorName
      attr_reader :author_attributes, :max_rows

      ##
      # @param [ScienceWire::AuthorAttributes] author_attributes
      # @param [String] max_rows
      def initialize(author_attributes, max_rows)
        @author_attributes = author_attributes
        @max_rows = max_rows
      end

      def generate
        <<-XML
          <![CDATA[
             #{query}
            ]]>
        XML
      end

      private

        def text_search_name_parts
          query = name_query_part
          query << name_query_part_with_middle(Regexp.last_match(1)) if author_attributes.middle_name =~ /^([[:alpha:]])/
          query
        end

        def name_query_part
          %("#{author_attributes.last_name},#{author_attributes.first_name}" or "#{author_attributes.last_name.upcase},#{author_attributes.first_name_initial.upcase}")
        end

        def name_query_part_with_middle(mid)
          " or \"#{author_attributes.last_name.upcase},#{author_attributes.first_name_initial.upcase}#{mid.upcase}\""
        end

        def text_search_query_predicate
          if author_attributes.institution.present? && author_attributes.email.present?
            "(#{text_search_name_parts}) and \"#{author_attributes.institution}\" and \"#{author_attributes.email}\""
          elsif author_attributes.institution.present? && !author_attributes.email.present?
            "(#{text_search_name_parts}) and \"#{author_attributes.institution}\""
          elsif !author_attributes.institution.present? && author_attributes.email.present?
            "(#{text_search_name_parts}) and \"#{author_attributes.email}\""
          else
            "(#{text_search_name_parts}) and \"stanford\""
          end
        end

        def query
          <<-XML
            <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
              <Criterion>
                <Criteria>
                  #{text_search_criterion}
                  #{last_name_filter_criterion}
                  #{first_name_filter_criterion}
                  #{document_category_criterion}
                </Criteria>
              </Criterion>
              #{sort_columns}
              <MaximumRows>#{max_rows}</MaximumRows>
            </query>
          XML
        end

        def text_search_criterion
          <<-XML
            <Criterion>
              <TextSearch>
                <QueryPredicate>#{text_search_query_predicate}</QueryPredicate>
                <SearchType>ExactMatch</SearchType>
                <Columns>AggregateText</Columns>
                <MaximumRows>#{max_rows}</MaximumRows>
              </TextSearch>
            </Criterion>
          XML
        end

        def last_name_filter_criterion
          if author_attributes.last_name.present?
            <<-XML
              <Criterion>
                <Filter>
                  <Column>AuthorLastName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>#{author_attributes.last_name.upcase}</Value>
                </Filter>
              </Criterion>
            XML
          else
            ''
          end
        end

        def first_name_filter_criterion
          if author_attributes.first_name.present?
            <<-XML
              <Criterion>
                <Filter>
                  <Column>AuthorFirstName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>#{author_attributes.first_name_initial.upcase}</Value>
                </Filter>
              </Criterion>
            XML
          else
            ''
          end
        end

        def document_category_criterion
          <<-XML
            <Criterion>
              <Filter>
                <Column>DocumentCategory</Column>
                <Operator>In</Operator>
                <Values>
                  <Value>Journal Document</Value>
                  <Value>Conference Proceeding Document</Value>
                </Values>
              </Filter>
            </Criterion>
          XML
        end

        def sort_columns
          <<-XML
            <Columns>
              <SortColumn>
                <Column>Rank</Column>
                <Direction>Descending</Direction>
              </SortColumn>
            </Columns>
          XML
        end
    end
  end
end
