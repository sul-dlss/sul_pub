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
        start_block << text_search_criterion << last_name_filter_criterion << first_name_filter_criterion << end_block
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

        def start_block
          <<-XML
          <![CDATA[
             <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/
            XMLSchema">
              <Criterion>
                <Criteria>
          XML
        end

        def text_search_criterion
          <<-XML
            <Criterion>
              <TextSearch>
                <QueryPredicate>(#{text_search_name_parts}) and Stanford</QueryPredicate>
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

        def end_block
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
          </Criteria>
            </Criterion>
            <Columns>
              <SortColumn>
                <Column>Rank</Column>
                <Direction>Descending</Direction>
              </SortColumn>
            </Columns>
           <MaximumRows>#{max_rows}</MaximumRows>
          </query>
            ]]>
          XML
        end
    end
  end
end
