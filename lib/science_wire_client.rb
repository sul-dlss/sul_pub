class ScienceWireClient

  def initialize
    @auth = YAML.load(File.open(Rails.root.join('config', 'sciencewire_auth.yaml')))
    @base_timeout_retries = 3
    @base_timeout_period = 100
  end

  def get_sciencewire_id_suggestions(last_name, first_name, middle_name, email_list, seed_list)

    ids = []
    ["Journal Document", "Conference Proceeding Document"].each do |category|
      bod = "<?xml version='1.0'?>
      <PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
        <Authors>
          <Author>
            <LastName>#{last_name}</LastName>
            <FirstName>#{first_name}</FirstName>
            <MiddleName>#{middle_name}</MiddleName>
         </Author>
      </Authors>
      <DocumentCategory>#{category}</DocumentCategory>"

      unless seed_list.blank?
        bod << '<PublicationItemIds>'
        bod << seed_list.collect { |pubId| "<int>#{pubId}</int>"}.join
        bod << '</PublicationItemIds>'
      end

      unless email_list.blank?
        bod << '<Emails>'
        bod <<   "<string>#{email_list}</string>"
        bod << '</Emails>'
      end

      bod << '<LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly>'
      bod << '</PublicationAuthorMatchParameters>'

      ids.concat make_sciencewire_suggestion_call(bod)
    end
    ids
	end

	def make_sciencewire_suggestion_call(body)
	    http = Net::HTTP.new(@auth[:get_uri], @auth[:get_port])

	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	    http.ssl_version = :SSLv3
	    timeout_retries ||= 3
	    timeout_period ||= 100
	    http.read_timeout = timeout_period
	    request = Net::HTTP::Post.new(@auth[:get_recommendation_path])
	    request["LicenseID"] = @auth[:get_license_id]
	    request["Host"] = @auth[:get_host]
	    request["Connection"] = "Keep-Alive"
	    request["Expect"] = "100-continue"
	    request["Content-Type"] = "text/xml"

	    request.body = body
	    response = http.request(request)
	    response_body = response.body
	    xml_doc = Nokogiri::XML(response_body)

	    xml_doc.xpath('/ArrayOfItemMatchResult/ItemMatchResult/PublicationItemID').collect { |itemId| itemId.text}

  rescue Timeout::Error => te
		timeout_retries -= 1
		if timeout_retries > 0
			# increase timeout
			timeout_period =+ 100
			retry
		else
			NotificationManager.handle_harvest_problem(te, "Timeout error on call to sciencewire api - #{DateTime.now}" )
			raise
		end
	rescue => e
		NotificationManager.handle_harvest_problem(e, "Problem with http call to sciencewire api")
		raise
	end




def query_sciencewire_by_author_name(first_name, middle_name, last_name, max_rows)

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

	unless middle_name.blank?
	  xml_query << "<Criterion>
	            <Filter>
	              <Column>AuthorMiddleName</Column>
	              <Operator>BeginsWith</Operator>
	              <Value>#{middle_name}</Value>
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

	    query_sciencewire(xml_query, 0, 3).xpath('//PublicationItem/PublicationItemID').collect { |itemId| itemId.text}

	end





	def pull_records_from_sciencewire_for_pmids(pmid_list)

	  pmidValuesAsXML = pmid_list.collect { |pmid| "&lt;Value&gt;#{pmid}&lt;/Value&gt;"}.join
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

	      query_sciencewire(xml_query, 3, 100)
	end

	def query_sciencewire_for_publication(first_name, last_name, middle_name, title, year, max_rows)
	  result = []
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
	    xml_results = query_sciencewire(xml_query, 3, 100)

	    xml_results.xpath('//PublicationItem').each do |sw_xml_doc|
	    # result << generate_json_for_pub(convert_sw_publication_doc_to_hash(sw_xml_doc))
	    	pub_hash = SciencewireSourceRecord.convert_sw_publication_doc_to_hash(sw_xml_doc)
	    	Publication.update_formatted_citations(pub_hash)
	    	result << pub_hash
	  end
	  result
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

    query_sciencewire(xml_query, 0, 60)

  end

	def query_sciencewire(xml_query, timeout_retries = 3, timeout_period = 100)
	    @base_timeout_retries = timeout_retries
	    @base_timeout_period = timeout_period
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
      http = setup_http
      request = Net::HTTP::Post.new(@auth[:publication_query_path])
      request["LicenseID"] = @auth[:get_license_id]
      request["Host"] = @auth[:get_host]
      request["Connection"] = "Keep-Alive"
      request["Expect"] = "100-continue"
      request["Content-Type"] = "text/xml"

      request.body = wrapped_xml_query

      response = http.request(request)
      response_body = response.body
      xml_doc = Nokogiri::XML(response_body)
      queryId = xml_doc.xpath('//queryID').text
    end
  end

  # @param [String] queryId used to identify a specific query to retrieve data for
  # @returns [Nokogiri::XML::Document] the response to the specific query
  def get_sciencewire_publication_response(queryId)
    with_timeout_handling do
      http = setup_http
      fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationQuery/#{queryId}?format=xml&v=version/3&page=0&pageSize=2147483647")
      fullPubsRequest["Content_Type"] = "text/xml"
      fullPubsRequest["LicenseID"] = @auth[:get_license_id]
      fullPubsRequest["Host"] = @auth[:get_host]
      fullPubsRequest["Connection"] = "Keep-Alive"

      fullPubResponse = http.request(fullPubsRequest)
      xml_doc = Nokogiri::XML(fullPubResponse.body)
      #   http.finish
      xml_doc
    end
  end

	def get_full_sciencewire_pubs_for_sciencewire_ids(sciencewire_ids)
		http = Net::HTTP.new(@auth[:get_uri], @auth[:get_port])
		timeout_retries ||= 3
		timeout_period ||= 500
		http.read_timeout = timeout_period
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	    http.ssl_version = :SSLv3
	    fullPubsRequest = Net::HTTP::Get.new(@auth[:get_pubs_for_ids_path] + sciencewire_ids)
	     fullPubsRequest["Content-Type"] = "text/xml"
	    fullPubsRequest["LicenseID"] = @auth[:get_license_id]
	    fullPubsRequest["Host"] = @auth[:get_host]
	    fullPubsRequest["Connection"] = "Keep-Alive"
	  #  http.start
	    fullPubResponse = http.request(fullPubsRequest).body
	    xml_doc = Nokogiri::XML(fullPubResponse)
	  #  http.finish
	    xml_doc
	rescue Timeout::Error => te
		timeout_retries -= 1
		if timeout_retries > 0
			# increase timeout
			timeout_period =+ 100
			retry
		else
			NotificationManager.handle_harvest_problem(te, "Timeout error on call to sciencewire api - #{DateTime.now}" )
			raise
		end
	rescue => e
		NotificationManager.handle_harvest_problem(e, "Problem with http call to sciencewire api")
		raise
	end

  def get_sw_xml_source_for_sw_id(sciencewire_id)
  	xml_doc = get_full_sciencewire_pubs_for_sciencewire_ids(sciencewire_id.to_s)
	  xml_doc.xpath('//PublicationItem').first
  end

private
  def with_timeout_handling
    timeout_retries = @base_timeout_retries
    timeout_period = @base_timeout_period

    begin
      yield
    rescue Timeout::Error => te
      timeout_retries -= 1
      if timeout_retries > 0
        # increase timeout
        timeout_period =+ 100
        retry
      else
        NotificationManager.handle_harvest_problem(te, "Timeout error on call to sciencewire api - #{DateTime.now}" )
        raise
      end
    rescue => e
      NotificationManager.handle_harvest_problem(e, "Problem with http call to sciencewire api")
      raise
    end
  end

  def setup_http
    http = Net::HTTP.new(@auth[:get_uri], @auth[:get_port])
    http.read_timeout = @base_timeout_period
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ssl_version = :SSLv3
    http
  end

end
