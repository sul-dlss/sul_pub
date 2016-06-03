module InstitutionEmailQueries
  def institution_and_email_provided
    <<-XML
    <![CDATA[
      <query xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <Criterion>
          <Criteria>
            <Criterion>
              <TextSearch>
                <QueryPredicate>("Brown,Charlie" or "Brown,C" or "cbrown@example.com") and "example"</QueryPredicate>
                <SearchType>ExactMatch</SearchType>
                <Columns>AggregateText</Columns>
                <MaximumRows>200</MaximumRows>
              </TextSearch>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorLastName</Column>
                <Operator>BeginsWith</Operator>
                <Value>BROWN</Value>
              </Filter>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorFirstName</Column>
                <Operator>BeginsWith</Operator>
                <Value>C</Value>
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

  def institution_and_no_email_provided
    <<-XML
    <![CDATA[
      <query xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <Criterion>
          <Criteria>
            <Criterion>
              <TextSearch>
                <QueryPredicate>("Brown,Charlie" or "Brown,C") and "example"</QueryPredicate>
                <SearchType>ExactMatch</SearchType>
                <Columns>AggregateText</Columns>
                <MaximumRows>200</MaximumRows>
              </TextSearch>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorLastName</Column>
                <Operator>BeginsWith</Operator>
                <Value>BROWN</Value>
              </Filter>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorFirstName</Column>
                <Operator>BeginsWith</Operator>
                <Value>C</Value>
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

  def no_institution_but_email_provided
    <<-XML
    <![CDATA[
      <query xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <Criterion>
          <Criteria>
            <Criterion>
              <TextSearch>
                <QueryPredicate>"Brown,Charlie" or "Brown,C" or "cbrown@example.com"</QueryPredicate>
                <SearchType>ExactMatch</SearchType>
                <Columns>AggregateText</Columns>
                <MaximumRows>200</MaximumRows>
              </TextSearch>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorLastName</Column>
                <Operator>BeginsWith</Operator>
                <Value>BROWN</Value>
              </Filter>
            </Criterion>
            <Criterion>
              <Filter>
                <Column>AuthorFirstName</Column>
                <Operator>BeginsWith</Operator>
                <Value>C</Value>
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

  def no_institution_no_email_provided
    <<-XML
    <![CDATA[
      <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <Criterion>
          <Criteria>
            <Criterion>
              <TextSearch>
                <QueryPredicate>"Brown,Charlie" or "Brown,C"</QueryPredicate>
                <SearchType>ExactMatch</SearchType>
                <Columns>AggregateText</Columns>
                <MaximumRows>200</MaximumRows>
              </TextSearch>
            </Criterion>
              <Criterion>
                <Filter>
                  <Column>AuthorLastName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>BROWN</Value>
                </Filter>
              </Criterion>
              <Criterion>
                <Filter>
                  <Column>AuthorFirstName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>C</Value>
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
