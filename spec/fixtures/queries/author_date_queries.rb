module AuthorDateQueries
  def author_with_dates
    <<-XML
    <![CDATA[
      <query xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <Criterion>
          <Criteria>
            <Criterion>
              <TextSearch>
                <QueryPredicate>("Bloggs,Fred" or "BLOGGS,F") and "example"</QueryPredicate>
                <SearchType>ExactMatch</SearchType>
                <Columns>AggregateText</Columns>
                <MaximumRows>200</MaximumRows>
              </TextSearch>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorLastName</Column>
                <Operator>BeginsWith</Operator>
                <Value>BLOGGS</Value>
              </Filter>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorFirstName</Column>
                <Operator>BeginsWith</Operator>
                <Value>F</Value>
              </Filter>
            </Criterion>

            <Criterion>
              <Filter>
                <Column>PublicationDate</Column>
                <Operator>GreaterThanOrEqualTo</Operator>
                <Value>1990-01-01</Value>
              </Filter>
            </Criterion>

            <Criterion>
              <Filter>
                <Column>PublicationDate</Column>
                <Operator>LessThanOrEqualTo</Operator>
                <Value>2000-12-31</Value>
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
end
