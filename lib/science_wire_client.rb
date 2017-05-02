class ScienceWireClient
  attr_reader :client
  def initialize
    @client = ScienceWire::Client.new(
      license_id: Settings.SCIENCEWIRE.LICENSE_ID,
      host: Settings.SCIENCEWIRE.HOST
    )
  end

  # Fetch a single publication by DOI, convert to pub_hash, then check the content for a match
  def self.working?
    pub_hashes = new.get_pub_by_doi('10.1038/nature11397', 1)
    pub_hashes.is_a?(Array) &&
    pub_hashes.first.is_a?(Hash) &&
    pub_hashes.first[:sw_id] == '61158927' &&
    pub_hashes.first[:title] == 'An index to assess the health and benefits of the global ocean'
  end

  ##
  # @param [AuthorAttributes] author_attributes
  # @return [Array<Integer>]
  def get_sciencewire_id_suggestions(author_attributes)
    client.id_suggestions(author_attributes)
  rescue Faraday::TimeoutError => te
    NotificationManager.error(te, 'Faraday::TimeoutError during ScienceWire Suggestions API call', self)
    raise
  rescue => e
    NotificationManager.error(e, "#{e.class.name} during ScienceWire Suggestions API call", self)
    raise
  end

  # @param [AuthorAtributes] author_attributes
  # @param [Integer] max_rows (200)
  # @return [Array<Integer>]
  def query_sciencewire_by_author_name(author_attributes, max_rows = 200)
    author_name = ScienceWire::Query::PublicationQueryByAuthorName.new(author_attributes, max_rows)
    xml_query = author_name.generate
    # TODO: use returned documents instead of selecting IDs
    xml_docs = query_sciencewire(xml_query)
    pubs = ScienceWirePublications.new(xml_docs)
    pubs.filter_publication_items.map(&:publication_item_id)
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
    xml_doc = send_sciencewire_publication_request(xml_query)
    queryId = xml_doc.xpath('//queryID').text.to_i
    queryResultRows = xml_doc.xpath('//queryResultRows').text.to_i
    get_sciencewire_publication_response(queryId, queryResultRows)
  end

  # @returns [Nokogiri::XML::Document] the ScienceWireQueryIDResponse
  def send_sciencewire_publication_request(xml_query)
    wrapped_xml_query = '<?xml version="1.0"?>
    <ScienceWireQueryXMLParameter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <xmlQuery>' + xml_query + '</xmlQuery>
    </ScienceWireQueryXMLParameter>'
    xml_doc = Nokogiri::XML(client.send_publication_query(wrapped_xml_query))
    validate_query_id_response_xml xml_doc
    xml_doc
  rescue Faraday::TimeoutError => te
    NotificationManager.error(te, 'Faraday::TimeoutError during ScienceWire Publication Query API POST request', self)
    raise
  rescue => e
    NotificationManager.error(e, "#{e.class.name} during ScienceWire Publication Query API POST request", self)
    raise
  end

  # @param [Integer] queryId used to identify a specific query result set
  # @param [Integer] queryResultRows the total number of results for a query
  # @returns [Nokogiri::XML::Document] the ArrayOfPublicationItem response
  def get_sciencewire_publication_response(queryId, queryResultRows)
    xml_doc = begin
      if queryResultRows > 0
        Nokogiri::XML(client.retrieve_publication_query(queryId, queryResultRows, 'xml'))
      else
        Nokogiri::XML '<ArrayOfPublicationItem/>'
      end
    end
    validate_array_of_publication_item_xml xml_doc
    xml_doc
  rescue Faraday::TimeoutError => te
    NotificationManager.error(te, 'Faraday::TimeoutError during ScienceWire Publication Query API GET request', self)
    raise
  rescue => e
    NotificationManager.error(e, "#{e.class.name} during ScienceWire Publication Query API GET request", self)
    raise
  end

  # @param sciencewire_ids [Array<Integer>] array of PublicationItemID integers
  # @returns [Nokogiri::XML::Document] the ArrayOfPublicationItem response
  def get_full_sciencewire_pubs_for_sciencewire_ids(sciencewire_ids)
    # Get the documents in batches, because the request is made as a GET and a very long
    # list of PublicationItemId values might exceed a URL length limit (approx. 2000 chars), see commentary in:
    # http://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers
    # Approx. 150 PublicationItemId values fits within 1500 chars (leaving room for the URL path); i.e.
    # ([100000000] * 150).join(',').length == 1499
    # So using batches of 100 is within the URL length limit and could also avoid some timeouts.
    sw_id_slices = sciencewire_ids.each_slice(100).to_a
    # Get the first set of 100 PublicationItem
    id_slice = sw_id_slices.shift
    xml_doc = Nokogiri::XML(client.publication_items(id_slice.join(','), 'xml'))
    validate_array_of_publication_item_xml xml_doc
    pub_array = xml_doc.at_xpath('//ArrayOfPublicationItem')
    # Collate additional results into pub_array
    sw_id_slices.each do |id_sliceN|
      xml_docN = Nokogiri::XML(client.publication_items(id_sliceN.join(','), 'xml'))
      validate_array_of_publication_item_xml xml_docN
      pub_arrayN = xml_docN.at_xpath('//ArrayOfPublicationItem')
      pub_array.children += pub_arrayN.children
    end
    # Check that all the PublicationItem are collated into xml_doc
    pub_items = xml_doc.xpath('//ArrayOfPublicationItem/PublicationItem')
    raise 'Failed to collate PublicationItems' unless pub_items.count == sciencewire_ids.count
    xml_doc
  rescue Faraday::TimeoutError => te
    NotificationManager.error(te, 'Faraday::TimeoutError during ScienceWire Publication Items API GET request', self)
    raise
  rescue => e
    NotificationManager.error(e, "#{e.class.name} during ScienceWire Publication Items API GET request", self)
    raise
  end

  # @param sciencewire_id [Integer] a PublicationItemID integer
  # @returns [Nokogiri::XML::Element] a PublicationItem element
  def get_sw_xml_source_for_sw_id(sciencewire_id)
    xml_doc = get_full_sciencewire_pubs_for_sciencewire_ids([sciencewire_id])
    xml_doc.xpath('//PublicationItem').first
  end

  private

  def validate_array_of_publication_item_xml(xml_doc)
    raise(ArgumentError, 'Did not receive a valid <ArrayOfPublicationItem>') unless
      xml_doc.is_a?(Nokogiri::XML::Document) && !xml_doc.xpath('//ArrayOfPublicationItem').empty?
  end

  def validate_query_id_response_xml(xml_doc)
    raise(ArgumentError, 'Did not receive a valid <ScienceWireQueryIDResponse>') unless
      xml_doc.is_a?(Nokogiri::XML::Document) &&
      !xml_doc.xpath('//ScienceWireQueryIDResponse').empty? &&
      !xml_doc.xpath('//queryID').empty? &&
      !xml_doc.xpath('//queryResultRows').empty?
  end

  def send_query_and_return_pub_hashes(xml_query)
    xml_results = query_sciencewire(xml_query)

    xml_results.xpath('//PublicationItem').map do |sw_xml_doc|
      pub_hash = SciencewireSourceRecord.convert_sw_publication_doc_to_hash(sw_xml_doc)
      h = PubHash.new(pub_hash)

      pub_hash[:apa_citation] = h.to_apa_citation
      pub_hash[:mla_citation] = h.to_mla_citation
      pub_hash[:chicago_citation] = h.to_chicago_citation
      pub_hash[:nlm_citation] = h.to_nlm_citation
      pub_hash
    end
  end
end
