module AuthorNameQueries
  def common_first_last_name
    <<-XML
    <![CDATA[
      <query xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <Criterion>
          <Criteria>
            <Criterion>
              <TextSearch>
                <QueryPredicate>("smith,james" or "SMITH,J") and "Example University"</QueryPredicate>
                <SearchType>ExactMatch</SearchType>
                <Columns>AggregateText</Columns>
                <MaximumRows>200</MaximumRows>
              </TextSearch>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorLastName</Column>
                <Operator>BeginsWith</Operator>
                <Value>SMITH</Value>
              </Filter>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorFirstName</Column>
                <Operator>BeginsWith</Operator>
                <Value>J</Value>
              </Filter>
            </Criterion>
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
        <MaximumRows>200</MaximumRows>
      </query>
    ]]>
    XML
  end

  def middle_name_only
    <<-XML
    <![CDATA[
      <query xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <Criterion>
          <Criteria>
            <Criterion>
              <TextSearch>
                <QueryPredicate>("," or "," or ",M") and "Stanford"</QueryPredicate>
                <SearchType>ExactMatch</SearchType>
                <Columns>AggregateText</Columns>
                <MaximumRows>200</MaximumRows>
              </TextSearch>
            </Criterion>
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
        <MaximumRows>200</MaximumRows>
      </query>
    ]]>
    XML
  end
end
