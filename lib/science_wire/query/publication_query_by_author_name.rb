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

        def name
          @name ||= author_attributes.name
        end

        def institution
          @institution ||= author_attributes.institution.normalize_name
        end

        # Assume that `author_attributes.email` is a string containing one email address
        # (the email is not an array of emails or a comma delimited list of emails).
        def text_search_query_predicate
          if institution.present? && author_attributes.email.present?
            "(#{name.text_search_query} or \"#{author_attributes.email}\") and \"#{institution}\""
          elsif institution.present? && !author_attributes.email.present?
            "(#{name.text_search_query}) and \"#{institution}\""
          elsif !institution.present? && author_attributes.email.present?
            "#{name.text_search_query} or \"#{author_attributes.email}\""
          else
            "(#{name.text_search_query}) and \"stanford\""
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
                  #{start_date_filter_criterion}
                  #{end_date_filter_criterion}
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
          if name.last.present?
            <<-XML
              <Criterion>
                <Filter>
                  <Column>AuthorLastName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>#{name.last.upcase}</Value>
                </Filter>
              </Criterion>
            XML
          else
            ''
          end
        end

        def first_name_filter_criterion
          if name.first.present?
            <<-XML
              <Criterion>
                <Filter>
                  <Column>AuthorFirstName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>#{name.first_initial}</Value>
                </Filter>
              </Criterion>
            XML
          else
            ''
          end
        end

        def start_date_filter_criterion
          if author_attributes.start_date.present?
            <<-XML
              <Criterion>
                <Filter>
                  <Column>PublicationDate</Column>
                  <Operator>GreaterThanOrEqualTo</Operator>
                  <Value>#{author_attributes.start_date}</Value>
                </Filter>
              </Criterion>
            XML
          else
            ''
          end
        end

        def end_date_filter_criterion
          if author_attributes.end_date.present?
            <<-XML
              <Criterion>
                <Filter>
                  <Column>PublicationDate</Column>
                  <Operator>LessThanOrEqualTo</Operator>
                  <Value>#{author_attributes.end_date}</Value>
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
