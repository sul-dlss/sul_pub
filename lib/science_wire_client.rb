class ScienceWireClient
  attr_reader :client
  def initialize
    @reject_types = Settings.sw_doc_types_to_skip.join('|')
    @client = ScienceWire::Client.new(
      license_id: Settings.SCIENCEWIRE.LICENSE_ID,
      host: Settings.SCIENCEWIRE.HOST
    )
  end

  # Fetch a single publication by DOI and convert to pub_hash
  def self.working?
    pub_hashes = new.get_pub_by_doi('10.1038/nature11397', 1)
    pub_hashes.present? && pub_hashes.length == 1 && pub_hashes.first.is_a?(Hash)
  end

  def get_sciencewire_id_suggestions(last_name, first_name, middle_name, email, seed_list)
    author_attributes = ScienceWire::AuthorAttributes.new(last_name, first_name, middle_name, email, seed_list)
    client.id_suggestions(author_attributes)
  rescue Faraday::TimeoutError => te
    NotificationManager.handle_harvest_problem(te, "Timeout error on call to sciencewire api - #{Time.zone.now}")
    raise
  rescue => e
    NotificationManager.handle_harvest_problem(e, 'Problem with http call to sciencewire api')
    raise
  end

  def query_sciencewire_by_author_name(first_name, middle_name, last_name, max_rows = 200)
    query = %("#{last_name},#{first_name}" or "#{(last_name || '').upcase},#{((first_name || '')[0] || '').upcase}")
    if middle_name && !middle_name.blank? && middle_name =~ /^([a-zA-Z])/
      query << " or \"#{(last_name || '').upcase},#{((first_name || '')[0] || '').upcase}#{Regexp.last_match(1).upcase}\""
    end

    xml_query = '<![CDATA[
       <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/
      XMLSchema">
        <Criterion>
          <Criteria>'

    xml_query << "<Criterion>
              <TextSearch>
                  <QueryPredicate>(#{query}) and Stanford</QueryPredicate>
                  <SearchType>ExactMatch</SearchType>
                  <Columns>AggregateText</Columns>
                  <MaximumRows>#{max_rows}</MaximumRows>
                  </TextSearch>
            </Criterion>"

    unless last_name.blank?
      xml_query << "<Criterion>
                <Filter>
                  <Column>AuthorLastName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>#{last_name.upcase}</Value>
                </Filter>
              </Criterion>"
    end
    unless first_name.blank?
      xml_query << "<Criterion>
                <Filter>
                  <Column>AuthorFirstName</Column>
                  <Operator>BeginsWith</Operator>
                  <Value>#{first_name[0].upcase}</Value>
                </Filter>
              </Criterion>"
    end

    xml_query << "<Criterion>
                    <Filter>
                      <Column>DocumentCategory</Column>
                      <Operator>In</Operator>
                      <Values>
                        <Value>Journal Document</Value>
                        <Value>Conference Proceeding Document</Value>
                      </Values>
                    </Filter>
                  </Criterion>"

    xml_query << "</Criteria>
        </Criterion>
        <Columns>
          <SortColumn>
            <Column>Rank</Column>
            <Direction>Descending</Direction>
          </SortColumn>
        </Columns>
       <MaximumRows>#{max_rows}</MaximumRows>
      </query>
      ]]>"

    # Only select Publication types that are not on the skip list
    # TODO: use returned documents instead of selecting IDs
    query_sciencewire(xml_query).xpath("//PublicationItem[regex_reject(DocumentTypeList, '#{@reject_types}')]/PublicationItemID", XpathUtils.new).collect(&:text)
  end

  def pull_records_from_sciencewire_for_pmids(pmids)
    pmid_list = Array(pmids)
    pmidValuesAsXML = pmid_list.collect { |pmid| "&lt;Value&gt;#{pmid}&lt;/Value&gt;" }.join
    xml_query = '&lt;query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"&gt;
              &lt;Criterion ConjunctionOperator="AND"&gt;
                &lt;Criteria&gt;
                  &lt;Criterion&gt;
                    &lt;Filter&gt;
                      &lt;Column&gt;PMID&lt;/Column&gt;
                      &lt;Operator&gt;In&lt;/Operator&gt;
                      &lt;Values&gt;' +
                pmidValuesAsXML +
                '&lt;/Values&gt;
                            &lt;/Filter&gt;
                          &lt;/Criterion&gt;
                        &lt;/Criteria&gt;
                      &lt;/Criterion&gt;
                      &lt;Columns&gt;
                        &lt;SortColumn&gt;
                          &lt;Column&gt;Rank&lt;/Column&gt;
                          &lt;Direction&gt;Descending&lt;/Direction&gt;
                        &lt;/SortColumn&gt;
                      &lt;/Columns&gt;
                      &lt;MaximumRows&gt;1000&lt;/MaximumRows&gt;
                    &lt;/query&gt;'

    query_sciencewire(xml_query)
  end

  def query_sciencewire_for_publication(first_name, last_name, _middle_name, title, year, max_rows)
    xml_query = '<![CDATA[
       <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/
      XMLSchema">
        <Criterion ConjunctionOperator="AND">
          <Criteria>'

    unless last_name.blank?
      xml_query << "<Criterion>
              <Filter>
                <Column>AuthorLastName</Column>
                <Operator>BeginsWith</Operator>
                <Value>#{last_name}</Value>
              </Filter>
            </Criterion>"
    end
    unless first_name.blank?
      xml_query << "<Criterion>
              <Filter>
                <Column>AuthorFirstName</Column>
                <Operator>BeginsWith</Operator>
                <Value>#{first_name}</Value>
              </Filter>
            </Criterion>"
    end
    unless title.blank?
      xml_query << "<Criterion>
              <Filter>
                <Column>Title</Column>
                <Operator>Contains</Operator>
                <Value>#{title}</Value>
              </Filter>
            </Criterion>"
    end
    unless year.blank?
      xml_query << "<Criterion>
              <Filter>
                <Column>PublicationYear</Column>
                <Operator>Equals</Operator>
                <Value>#{year}</Value>
              </Filter>
            </Criterion>"
    end
    xml_query << "</Criteria>
        </Criterion>
        <Columns>
          <SortColumn>
            <Column>Rank</Column>
            <Direction>Descending</Direction>
          </SortColumn>
        </Columns>
       <MaximumRows>#{max_rows}</MaximumRows>
      </query>
      ]]>"

    send_query_and_return_pub_hashes xml_query
  end

  def get_pub_by_doi(doi, max_rows = 200)
    query = <<-XML
      <![CDATA[
      <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
          <Criterion>
              <Criteria>
                  <Criterion>
                      <Filter>
                          <Column>DOI</Column>
                          <Operator>Equals</Operator>
                          <Value>#{doi}</Value>
                      </Filter>
                  </Criterion>
              </Criteria>
          </Criterion>
          <MaximumRows>#{max_rows}</MaximumRows>
      </query>
      ]]>
    XML

    send_query_and_return_pub_hashes query
  end

  # @params [Array<String>] wos_ids The WebOfScience Document Ids that are being requested
  # @return [Nokogiri::XML::Document]
  def get_full_sciencewire_pubs_for_wos_ids(wos_ids)
    xml_query = %(<![CDATA[
      <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <Criterion ConjunctionOperator="AND">
          <Criteria>
            <Criterion>
              <Filter>
                <Column>WoSItemID</Column>
                <Operator>In</Operator>
                <Values>\n)

    wos_ids.each do |id|
      xml_query << "<Value>#{id}</Value>\n"
    end

    xml_query << '</Values>
                </Filter>
              </Criterion>
            </Criteria>
          </Criterion>'

    xml_query << "<Columns>
            <SortColumn>
              <Column>PublicationItemID</Column>
              <Direction>Ascending</Direction>
            </SortColumn>
          </Columns>
        </query>
    ]]>"

    query_sciencewire(xml_query)
  end

  def query_sciencewire(xml_query)
    queryId = send_sciencewire_publication_request(xml_query)
    get_sciencewire_publication_response(queryId)
  end

  # @returns [String] the queryId to use for fetching results
  def send_sciencewire_publication_request(xml_query)
    with_timeout_handling do
      wrapped_xml_query = '<?xml version="1.0"?>
      <ScienceWireQueryXMLParameter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <xmlQuery>' + xml_query + '</xmlQuery>
      </ScienceWireQueryXMLParameter>'
      xml_doc = Nokogiri::XML(client.send_publication_query(wrapped_xml_query))
      xml_doc.xpath('//queryID').text
    end
  end

  # @param [String] queryId used to identify a specific query to retrieve data for
  # @returns [Nokogiri::XML::Document] the response to the specific query
  def get_sciencewire_publication_response(queryId)
    with_timeout_handling do
      xml_doc = Nokogiri::XML(client.retrieve_publication_query(queryId))
      xml_doc
    end
  end

  def get_full_sciencewire_pubs_for_sciencewire_ids(sciencewire_ids)
    Nokogiri::XML(client.publication_items(sciencewire_ids))
  rescue Faraday::TimeoutError => te
    NotificationManager.handle_harvest_problem(te, "Timeout error on call to sciencewire api - #{Time.zone.now}")
    raise
  rescue => e
    NotificationManager.handle_harvest_problem(e, 'Problem with http call to sciencewire api')
    raise
  end

  def get_sw_xml_source_for_sw_id(sciencewire_id)
    xml_doc = get_full_sciencewire_pubs_for_sciencewire_ids(sciencewire_id.to_s)
    xml_doc.xpath('//PublicationItem').first
  end

  private

  def send_query_and_return_pub_hashes(xml_query)
    xml_results = query_sciencewire(xml_query)

    xml_results.xpath('//PublicationItem').map do |sw_xml_doc|
      pub_hash = SciencewireSourceRecord.convert_sw_publication_doc_to_hash(sw_xml_doc)
      h = PubHash.new(pub_hash)

      pub_hash[:apa_citation] = h.to_apa_citation
      pub_hash[:mla_citation] = h.to_mla_citation
      pub_hash[:chicago_citation] = h.to_chicago_citation
      pub_hash
    end
  end

  def with_timeout_handling
  yield
  rescue Faraday::TimeoutError => te
    NotificationManager.handle_harvest_problem(te, "Timeout error on call to sciencewire api - #{Time.zone.now}")
    raise
  rescue => e
    NotificationManager.handle_harvest_problem(e, 'Problem with http call to sciencewire api')
    raise
  end
end
