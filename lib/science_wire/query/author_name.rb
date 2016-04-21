module ScienceWire
  module Query
    class AuthorName
      attr_reader :first_name, :middle_name, :last_name, :max_rows

      def initialize(first_name, middle_name, last_name, max_rows)
        @first_name = first_name
        @middle_name = middle_name
        @last_name = last_name
        @max_rows = max_rows
      end

      def generate
        start_block << text_search_criterion << last_name_filter_criterion << first_name_filter_criterion << end_block
      end

      private

        def text_search_name_parts
          query = name_query_part
          if middle_name && !middle_name.blank? && middle_name =~ /^([a-zA-Z])/
            query << name_query_part_with_middle(Regexp.last_match(1))
          end
          query
        end

        def name_query_part
          %("#{last_name},#{first_name}" or "#{last_name.to_s.upcase},#{first_name_initial.upcase}")
        end

        def name_query_part_with_middle(mid)
          " or \"#{last_name.to_s.upcase},#{first_name_initial.upcase}#{mid.upcase}\""
        end

        def first_name_initial
          first_name.to_s[0].to_s
        end

        def start_block
          <<-XML.strip_heredoc
          <![CDATA[
             <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/
            XMLSchema">
              <Criterion>
                <Criteria>
          XML
        end

        def text_search_criterion
          <<-XML.strip_heredoc
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
          if last_name.present?
            <<-XML.strip_heredoc
              <Criterion>
                <Filter>
                  <Column>AuthorLastName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>#{last_name.upcase}</Value>
                </Filter>
              </Criterion>
            XML
          else
            ''
          end
        end

        def first_name_filter_criterion
          if first_name.present?
            <<-XML.strip_heredoc
              <Criterion>
                <Filter>
                  <Column>AuthorFirstName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>#{first_name_initial.upcase}</Value>
                </Filter>
              </Criterion>
            XML
          else
            ''
          end
        end

        def end_block
          <<-XML.strip_heredoc
          <Criterion>
              <Filter>
                <Column>DocumentCategory</Column>
                <Operator>In</Operator>
                <Values>
                  <Value>Journal Document</Value>
                  <Value>Conference Proceeding Document</Value>
                </Values>
              </Filter>
            </Criterion></Criteria>
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
