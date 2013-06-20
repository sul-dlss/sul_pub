class ScienceWireClient

	
	def get_sciencewire_id_suggestions(last_name, first_name, middle_name, email_list, seed_list)

		auth = YAML.load(File.open(Rails.root.join('config', 'sciencewire_auth.yaml')))
	    http = Net::HTTP.new(auth[:get_uri], auth[:get_port])
	    
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	    http.ssl_version = :SSLv3
	    timeout_period ||= 500
	    http.read_timeout = timeout_period
	    request = Net::HTTP::Post.new(auth[:get_recommendation_path])
	    request["LicenseID"] = auth[:get_license_id]
	    request["Host"] = auth[:get_host]
	    request["Connection"] = "Keep-Alive"
	    request["Expect"] = "100-continue"
	    request["Content-Type"] = "text/xml"

	    bod = "<?xml version='1.0'?>
			<PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
			  <Authors>
			    <Author>
			      <LastName>#{last_name}</LastName>
			      <FirstName>#{first_name}</FirstName>
			      <MiddleName>#{middle_name}</MiddleName>
			      <City>Stanford</City>
			      <State>CA</State>
			      <Country>USA</Country>
			    </Author>
			  </Authors>
			  <DocumentCategory>Journal Document</DocumentCategory>"

	    unless seed_list.blank?
	      bod << '<PublicationItemIds>'
	      bod << seed_list.collect { |pubId| "<int>#{pubId}</int>"}.join
	      bod << '</PublicationItemIds>'
	    end

	    unless email_list.blank?
	      bod << '<Emails>'
	      bod <<   "<string>#{email_list}</string>"
	      #.collect { |email| "<string>#{email}</string>"}.join
	      bod << '</Emails>'
	    end

	    bod << '<LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly>'
	    bod << '</PublicationAuthorMatchParameters>'

	    request.body = bod
	 #  puts bod
	    response = http.request(request)
	    response_body = response.body
	   # puts response_body
	    xml_doc = Nokogiri::XML(response_body)

	    #puts xml_doc.to_xml
	    xml_doc.xpath('/ArrayOfItemMatchResult/ItemMatchResult/PublicationItemID').collect { |itemId| itemId.text}
	    
end

def query_sciencewire_by_author_name(first_name, middle_name, last_name, max_rows)
	  
	  xml_query = '<![CDATA[
	     <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/
	    XMLSchema">
	      <Criterion ConjunctionOperator="AND">
	        <Criteria>'

	unless last_name.blank?
	  xml_query << '<Criterion>
	            <Filter>
	              <Column>AuthorLastName</Column>
	              <Operator>Equals</Operator>
	              <Value>' + last_name + '</Value>
	            </Filter>
	          </Criterion>' 
	end
	unless first_name.blank?
	  xml_query << '<Criterion>
	            <Filter>
	              <Column>AuthorFirstName</Column>
	              <Operator>BeginsWith</Operator>
	              <Value>' + first_name + '</Value>
	            </Filter>
	          </Criterion>' 
	end

	unless first_name.blank?
	  xml_query << '<Criterion>
	            <Filter>
	              <Column>AuthorMiddleName</Column>
	              <Operator>BeginsWith</Operator>
	              <Value>' + first_name + '</Value>
	            </Filter>
	          </Criterion>' 
	end
	
	   xml_query << '</Criteria>
	      </Criterion>
	      <Columns>
	        <SortColumn>
	          <Column>Rank</Column>
	          <Direction>Descending</Direction>
	        </SortColumn>
	      </Columns>
	     <MaximumRows>' + max_rows.to_s + '</MaximumRows>
	    </query>
	    ]]>'

	    query_sciencewire(xml_query).xpath('//PublicationItem/PublicationItemID').collect { |itemId| itemId.text}
		
	end

def get_full_sciencewire_pubs_for_sciencewire_ids(sciencewire_ids)
	    #puts "sciencewire guesses : " + sciencewire_ids
	    #puts "total guesses: " + sciencewire_ids.split(',').length.to_s
	# longstring = '75730,7538775,62748461,3312687,9405169,60260389,53871550,540355,33750376,29693881,47663005,62653795,7399755,33766313,3481335,53867974,7400481,32070810,44498,60911392,60920503,1130131,372102,54275236,60826530,794058,1650795,2926117,5620804,5962108,7672897,29187335,30317932,30557232,31624868,33177491,59581844,62502628,8965796,8714382,3836129,33047462,7794139,3878419,32760709,60271837,2947683,62402077,53824620,32673308,31165181,3844888,4753475,43512451,55057387,43293036,5805724,577200,30191233,8522664,32675209,33592323,3279945,31273904,29777990,45880984,7095013,7723282,9889580,4107253,62743366,4047031,24567137,7881842,29181582,31312255,7862479,62655229,54341971,7720777,8409611,24067215,19098718,21832584,23659408,1014558,47204001,4427246,4661392,31233117,47305929,16615195,7912077,611518,8268524,29213969,21654873,23053652,23367427,26295163,21792264,17517318,9652677,23409912,23171694,24290100,26431847,21900781,18040369,10295402,19905921,23779936,62542812,23111920,23457494,9576774,25046273,25883302,10459074,24994501,26471227,2135874,33373164,21670297,19215006,22917106,27236810,2190531,29160228,54639433,19892951,25001379,5015036,4384444,32752911,62367968,27796421,3634553,9792096,16890081,21737823,25914249,22043195,33220117,23987601,23823604,20918316,2757533,20100070,23195771,30705666,60877697,19725092,24475784,54555329,1327867,25067899,23201453,19704552,2846500,19406750,19649827,16051894,23307283,436237,17170028,22531867,17497397,24038642,4355601,24205624,25788502,24203767,25594985,5059172,27130910,21917828,42960659,18608079,21809027,20734399,23561775,24249627,4622616,23920615,20837583,22518381,18579316,24844551,21817785,20022505,16612006,27339882,1986576,20507674,22989182,21808842,27142127,24091924,22970654,43349744,1435670,25416689,20000315,23850135,25416025,5141327,22833324,21913316,24244572,18083243,23758800,19081323,18850080,15345556,20145010,29356618,20786567,42073740,25118410,24874447,42190607,45399508,18646849,39187931,59741637,38855406,9519175,3332437,4034905,5853391,6696910,690024,53352755,32913152,3359318,7648883,1824997,1573832,1481968,29571231,1428494,5197296,8272525,31883212,4270967,5629152,31464643,47492593,61530013,1262815,45881062,1601979,29124252,31638154,3781065,55079691,9949551,47452492'
	# id_test = '75730,7538775,62748461,3312687,9405169,60260389,53871550,540355,33750376,29693881,47663005,62653795,7399755,33766313,3481335,53867974,7400481,32070810,44498,60911392,60920503,1130131,372102,54275236,60826530,794058,1650795,2926117,5620804,5962108,7672897,29187335,30317932,30557232,31624868,33177491,59581844,62502628,8965796,8714382,3836129,33047462,7794139,3878419,32760709,60271837,2947683,62402077,53824620,32673308,31165181,3844888,4753475,43512451,55057387,43293036,5805724,577200,30191233,8522664,32675209,33592323,3279945,31273904,29777990,45880984,7095013,7723282,9889580,4107253,62743366,4047031,24567137,7881842,29181582,31312255,7862479,62655229,54341971,7720777,8409611,24067215,19098718,21832584,23659408,1014558,47204001,4427246,4661392,31233117,47305929,16615195,7912077,611518,8268524,29213969,21654873,23053652,23367427,26295163,21792264,17517318,9652677,23409912,23171694,24290100,26431847,21900781,18040369,10295402,19905921,23779936,62542812,23111920,23457494,9576774,25046273,25883302,10459074,24994501,26471227,2135874,33373164,21670297,19215006,22917106,27236810,2190531,29160228,54639433,19892951,25001379,5015036,4384444,32752911,62367968,27796421,3634553,9792096,16890081,21737823,25914249,22043195,33220117,23987601,23823604,20918316,2757533,20100070,23195771,30705666,60877697,19725092,24475784,54555329,1327867,25067899,23201453,19704552,2846500,19406750,19649827,16051894,23307283,436237,17170028,22531867,17497397,24038642,4355601,24205624,25788502,24203767,25594985,5059172,27130910,21917828,42960659,18608079,21809027,20734399,23561775,24249627,4622616,23920615,20837583,22518381,18579316,24844551,21817785,20022505,16612006,27339882,1986576,20507674,22989182,21808842,27142127,24091924,22970654,43349744,1435670,25416689,20000315,23850135,25416025,5141327,22833324,21913316,24244572,18083243,23758800,19081323,18850080,15345556,20145010,29356618,20786567,42073740,25118410,24874447,42190607,45399508,18646849,39187931,59741637'
	# puts "number of ids: " + id_test.split(',').length.to_s
	auth = YAML.load(File.open(Rails.root.join('config', 'sciencewire_auth.yaml')))
	http = Net::HTTP.new(auth[:get_uri], auth[:get_port])
	timeout_period ||= 500
	http.read_timeout = timeout_period
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ssl_version = :SSLv3
    fullPubsRequest = Net::HTTP::Get.new(auth[:get_pubs_for_ids_path] + sciencewire_ids)
     fullPubsRequest["Content-Type"] = "text/xml"
    fullPubsRequest["LicenseID"] = auth[:get_license_id]
    fullPubsRequest["Host"] = auth[:get_host]
    fullPubsRequest["Connection"] = "Keep-Alive"

    fullPubResponse = http.request(fullPubsRequest).body
  	#puts fullPubResponse.to_s
    xml_doc = Nokogiri::XML(fullPubResponse)
    #http.finish
    xml_doc
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
	         
	      query_sciencewire(xml_query)
	end

	def query_sciencewire_for_publication(first_name, last_name, middle_name, title, year, max_rows)
	  result = []
	  xml_query = '<![CDATA[
	     <query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/
	    XMLSchema">
	      <Criterion ConjunctionOperator="AND">
	        <Criteria>'

	unless last_name.blank?
	  xml_query << '<Criterion>
	            <Filter>
	              <Column>AuthorLastName</Column>
	              <Operator>BeginsWith</Operator>
	              <Value>' + last_name + '</Value>
	            </Filter>
	          </Criterion>' 
	end
	unless first_name.blank?
	  xml_query << '<Criterion>
	            <Filter>
	              <Column>AuthorFirstName</Column>
	              <Operator>BeginsWith</Operator>
	              <Value>' + first_name + '</Value>
	            </Filter>
	          </Criterion>' 
	end
	unless title.blank?
	  xml_query << '<Criterion>
	            <Filter>
	              <Column>Title</Column>
	              <Operator>Contains</Operator>
	              <Value>' + title + '</Value>
	            </Filter>
	          </Criterion>' 
	end
	unless year.blank?
	  xml_query << '<Criterion>
	            <Filter>
	              <Column>PublicationYear</Column> 
	              <Operator>Equals</Operator> 
	              <Value>' + year.to_s + '</Value>
	            </Filter>
	          </Criterion>' 
	end
	   xml_query << '</Criteria>
	      </Criterion>
	      <Columns>
	        <SortColumn>
	          <Column>Rank</Column>
	          <Direction>Descending</Direction>
	        </SortColumn>
	      </Columns>
	     <MaximumRows>' + max_rows.to_s + '</MaximumRows>
	    </query>
	    ]]>'
	    xml_results = query_sciencewire(xml_query)

	    xml_results.xpath('//PublicationItem').each do |sw_xml_doc|
	    # result << generate_json_for_pub(convert_sw_publication_doc_to_hash(sw_xml_doc))    
	    	pub_hash = SciencewireSourceRecord.convert_sw_publication_doc_to_hash(sw_xml_doc)
	    	Publication.update_formatted_citations(pub_hash)
	    	result << pub_hash
	  end 
	  result
	end


	

	def query_sciencewire(xml_query)

	  wrapped_xml_query = '<?xml version="1.0"?>
	          <ScienceWireQueryXMLParameter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	            <xmlQuery>' + xml_query + '</xmlQuery>
	          </ScienceWireQueryXMLParameter>'
	    auth = YAML.load(File.open(Rails.root.join('config', 'sciencewire_auth.yaml')))
	    http = Net::HTTP.new(auth[:get_uri], auth[:get_port])
	    timeout_period ||= 500
	    http.read_timeout = timeout_period
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	    http.ssl_version = :SSLv3
	    request = Net::HTTP::Post.new(auth[:publication_query_path])
	    request["LicenseID"] = auth[:get_license_id]
    	request["Host"] = auth[:get_host]
	    request["Connection"] = "Keep-Alive"
	    request["Expect"] = "100-continue"
	    request["Content-Type"] = "text/xml"
	    
	    request.body = wrapped_xml_query

	    http.start

	    response = http.request(request)
	    response_body = response.body
	    xml_doc = Nokogiri::XML(response_body)
	    queryId = xml_doc.xpath('//queryID').text

	    fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationQuery/#{queryId}?format=xml&v=version/3&page=0&pageSize=2147483647")
	    fullPubsRequest["Content_Type"] = "text/xml"
	    fullPubsRequest["LicenseID"] = auth[:get_license_id]
    	fullPubsRequest["Host"] = auth[:get_host]
	    fullPubsRequest["Connection"] = "Keep-Alive"

	    fullPubResponse = http.request(fullPubsRequest)
	    xml_doc = Nokogiri::XML(fullPubResponse.body)
	    http.finish
	    xml_doc
	   
	  end

def get_sw_xml_source_for_sw_id(sciencewire_id)
  		auth = YAML.load(File.open(Rails.root.join('config', 'sciencewire_auth.yaml')))
	    http = Net::HTTP.new(auth[:get_uri], auth[:get_port])
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	    http.ssl_version = :SSLv3
	    timeout_period ||= 500
	    http.read_timeout = timeout_period
  		fullPubsRequest = Net::HTTP::Get.new(auth[:get_pubs_for_ids_path] + sciencewire_id.to_s)
	    fullPubsRequest["Content-Type"] = "text/xml"
	    fullPubsRequest["LicenseID"] = auth[:get_license_id]
    	fullPubsRequest["Host"] = auth[:get_host]
	    fullPubsRequest["Connection"] = "Keep-Alive"
	    http.start
	    fullPubResponse = http.request(fullPubsRequest).body
	  	#puts fullPubResponse.to_s
	    xml_doc = Nokogiri::XML(fullPubResponse)
	    http.finish
	    
	    xml_doc.xpath('//PublicationItem').first    
  	end


end
