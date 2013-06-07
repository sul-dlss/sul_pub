require 'nokogiri'
require 'settings'
require 'activerecord-import'
require 'dotiw'

class SciencewireSourceRecord < ActiveRecord::Base

  	attr_accessible :is_active, :lock_version, :pmid, :sciencewire_id, :source_data, :source_fingerprint
  	#validates_uniqueness_of :sciencewire_id

  	@@sw_conference_proceedings_type_strings ||= Settings.sw_doc_type_mappings.conference.split(',')
	@@sw_book_type_strings ||= Settings.sw_doc_type_mappings.book.split(',')

	include ActionView::Helpers::DateHelper
	# one instance method, the rest are class methods
	def get_source_as_hash 
		SciencewireSourceRecord.convert_sw_publication_doc_to_hash(Nokogiri::XML(self.source_data).xpath('//PublicationItem'))
	end

	def self.get_pub_by_pmid(pmid)
		sw_pub_hash = get_sciencewire_hash_for_pmid(pmid)
        unless sw_pub_hash.nil?
          pub = Publication.new(
            active: true,
            title: sw_pub_hash[:title],
            year: sw_pub_hash[:year],
     		pages: sw_pub_hash[:pages],
     		issn: sw_pub_hash[:issn],
          	publication_type: pub_hash[:type],
            sciencewire_id: sw_pub_hash[:sw_id],
            pmid: pmid) 
          pub.build_from_sciencewire_hash(sw_pub_hash)
          pub
      	end
	end

	def self.get_pub_by_sciencewire_id(sciencewire_id)
		sw_pub_hash = get_sciencewire_hash_for_sw_id(sciencewire_id)
        unless sw_pub_hash.nil?
          pub = Publication.new(
            active: true,
            title: sw_pub_hash[:title],
            year: sw_pub_hash[:year],
     		pages: sw_pub_hash[:pages],
     		issn: sw_pub_hash[:issn],
          	publication_type: sw_pub_hash[:type],
            sciencewire_id: sciencewire_id,
            pmid: sw_pub_hash[:pmid]) 
          pub.build_from_sciencewire_hash(sw_pub_hash)
          pub
      	end
	end

	def self.get_sciencewire_hash_for_sw_id(sciencewire_id)
  		sciencewire_source_record = get_sciencewire_source_record_for_sw_id(sciencewire_id)
  		unless sciencewire_source_record.nil?
  			sciencewire_source_record.get_source_as_hash
  		end
  	end

	def self.get_sciencewire_hash_for_pmid(pmid)
  		sciencewire_source_record = get_sciencewire_source_record_for_pmid(pmid)
  		unless sciencewire_source_record.nil?
  			sciencewire_source_record.get_source_as_hash
  		end
  	end

	def self.get_sciencewire_source_record_for_sw_id(sw_id)
  		SciencewireSourceRecord.where(sciencewire_id: sw_id).first || SciencewireSourceRecord.get_sciencewire_source_record_from_sciencewire_by_sw_id(sw_id)
  	end

  	def self.get_sciencewire_source_record_for_pmid(pmid)
  		SciencewireSourceRecord.where(pmid: pmid).first || SciencewireSourceRecord.get_sciencewire_source_record_from_sciencewire(pmid)
  	end

  	def self.get_sciencewire_source_record_from_sciencewire(pmid)
  		get_and_store_sw_source_records([pmid])
  		SciencewireSourceRecord.where[pmid: pmid].first
  	end

	def self.get_sciencewire_source_record_from_sciencewire_by_sw_id(sciencewire_id)
  		get_and_store_sw_source_record_for_sw_id(sciencewire_id)
  		SciencewireSourceRecord.where(sciencewire_id: sciencewire_id).first
  	end

  	def self.get_and_store_sw_source_record_for_sw_id(sciencewire_id)
  		http = Net::HTTP.new("sciencewirerest.discoverylogic.com", 443)
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	    http.ssl_version = :SSLv3

  		fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationItems?format=xml&publicationItemIDs=" + sciencewire_id.to_s)
	    fullPubsRequest["Content-Type"] = "text/xml"
	    fullPubsRequest["LicenseID"] = "***REMOVED***"
	    fullPubsRequest["Host"] = "sciencewirerest.discoverylogic.com"
	    fullPubsRequest["Connection"] = "Keep-Alive"
	    http.start
	    fullPubResponse = http.request(fullPubsRequest).body
	  	#puts fullPubResponse.to_s
	    xml_doc = Nokogiri::XML(fullPubResponse)
	    http.finish
	    
	    xml_doc.xpath('//PublicationItem').each do |sw_record_doc|
	      pmid = sw_record_doc.xpath("PMID").text
	      sciencewire_id = sw_record_doc.xpath("PublicationItemID").text
	             
	        SciencewireSourceRecord.where(sciencewire_id: sciencewire_id).first_or_create(
	                      :source_data => sw_record_doc.to_xml,
	                      :is_active => true,
	                      :pmid => pmid,
	                      :source_fingerprint => Digest::SHA2.hexdigest(sw_record_doc))
	            
	   puts "the source data: "
	   puts sw_record_doc.to_xml
	    end
  	end

	#get and store sciencewire source records for pmid list 
	def self.get_and_store_sw_source_records(pmids)
	    sw_records_doc = pull_records_from_sciencewire_for_pmids(pmids)
	    count = 0
	    source_records = []
	    sw_records_doc.xpath('//PublicationItem').each do |sw_record_doc|
	      pmid = sw_record_doc.xpath("PMID").text
	      sciencewire_id = sw_record_doc.xpath("PublicationItemID").text
	      begin        
	        count += 1
	        pmids.delete(pmid)
	              
	        source_records << SciencewireSourceRecord.new(
	                      :sciencewire_id => sciencewire_id,
	                      :source_data => sw_record_doc.to_xml,
	                      :is_active => true,
	                      :pmid => pmid,
	                      :source_fingerprint => Digest::SHA2.hexdigest(sw_record_doc))
	            
	      rescue Exception => e  
	        puts e.message  
	        #puts e.backtrace.inspect  
	        puts "The offending pmid: " + pmid.to_s
	      end
	    end
	  #  puts source_records.length.to_s + " records about to be created."
	    SciencewireSourceRecord.import source_records 
	  #  puts count.to_s + " pmids were processed. "
	  #  puts pmids.length.to_s + " pmids weren't processed: " 
	   # cap_pub_data_for_this_batch.each_key { |k| puts k.to_s}
	 end

	#harverst sciencewire records using author information
	def self.harvest_pubs_from_sciencewire_for_all_authors()
		include ActionView::Helpers::DateHelper
	    #Author.find_each(:batch_size => 100) do |author|
	    # random = rand(Author.count - 50)
	    #  author = Author.new(:pubmed_last_name => "levin", pubmed_first_initial: "c", pubmed_middle_initial: "s", sunetid: "cslevin")
	     #author = Author.new(:pubmed_last_name => "lee", pubmed_first_initial: "j", pubmed_middle_initial: "t", sunetid: "jtlee")
	    start_time = Time.now
	    harvested_count = 0
	    author_count = 0
	    @sw_harvest_logger = Logger.new(Rails.root.join('log', 'sw_test_harvest.log'))
	    @sw_harvest_logger.info "Started Don's engineering subset harvest " + DateTime.now.to_s
	    IO.foreach(Rails.root.join('app', 'data', '2013_06_06_univIds_from_don_for_harvest_qa.txt')) do |line|
	    	#Author.where(active_in_cap: true).limit(100).offset(19086).find_each(:batch_size => 500) do |author|
	    	
	    	author = Author.where(university_id: line).first
	    	if author 
	    		@harvested_for_author_count = 0
		    	author_count += 1
		        last_name = author.official_last_name
		        first_name = author.official_first_name
		        middle_name = author.official_middle_name
		        profile_id = author.cap_profile_id
		        email = author.email

		        seed_list = author.approved_sw_ids.collect { | sw_id | sw_id.identifier_value }
		        if author_count%10 == 0
		        	string_to_print = "Harvested #{harvested_count.to_s} records for #{author_count.to_s} authors - " + DateTime.now.to_s
		        	@sw_harvest_logger.info string_to_print
		        	puts string_to_print
		        end
		        email_list = [email] unless email.blank?
		       # puts "email list: " + email_list.to_s
		       # puts "seed pubs: " + seed_list.to_s
		       
		       # split out the call to get sw guesses to first get the sciencwire ids, use these to first filter
		       # out existing contribution:
		       # Publication.joins(:contributions => :author).
            	# where("authors.id=? and publications.sciencewire_id=?, author.id, sciencewire_id)

		        sw_records_doc = get_sw_guesses(last_name, first_name, middle_name, email_list, seed_list)
		        sw_records_doc.xpath('//PublicationItem').each do |sw_doc|
		        	harvested_count += 1
		        	@harvested_for_author_count += 1
		        	#puts "record: " + sw_doc.xpath("Title").text
		        	#puts "sw id: " + sw_doc.xpath("PublicationItemID").text
		        	#puts "author: " + sw_doc.xpath('AuthorList').text
		         # ActiveRecord::Base.transaction do
		          	create_or_update_pub_and_contribution_with_harvested_sw_doc(sw_doc, author)    
		        #  end # transaction end
		      	end 
		      	@sw_harvest_logger.info "#{author.official_last_name} - #{line} has #@harvested_for_author_count new harvested records."
	      	else
	      		@sw_harvest_logger.info "no author found for university_id: " + line
	      	end
	    end 
	    @sw_harvest_logger.info "Finished harvest at " + DateTime.now.to_s
    	@sw_harvest_logger.info harvested_count.to_s + " records were harvested for " + author_count.to_s + " authors." 

	end

	

	def self.create_or_update_pub_and_contribution_with_harvested_sw_doc(incoming_sw_xml_doc, author)
	    pub_hash = convert_sw_publication_doc_to_hash(incoming_sw_xml_doc) 
	    pmid = pub_hash[:pmid]
	    sciencewire_id = pub_hash[:sw_id]
	    title = pub_hash[:title]
	    year = pub_hash[:year]
	    issn = pub_hash[:issn]
	    pages = pub_hash[:pages]
	    type = pub_hash[:type]
	    status = 'new'
	    visibility = "private"
	    featured = false
	    
	    
	    save_or_update_sw_source_record(sciencewire_id, pmid, incoming_sw_xml_doc.to_xml)
	    
	    #disambig rules:
	    #1.check for existing pub by sw_id, pmid
	    #2.Look for ISSN. If matches, need to also check for year and first page.
		#3.Look for Title, year, starting page
	    pub = Publication.where(sciencewire_id: sciencewire_id).first
	    if pub.nil? 
	    	Publication.where(pmid: pmid).first unless pmid.blank?
	    end
	    if pub.nil? && !issn.blank? && !pages.blank?
	    	Publication.where(issn: issn, pages: pages, year: year).first
	    end
	    if pub.nil? 
	    	Publication.where(title: title, year: year, pages: pages).first
	    end
	    # if still nothing then create a new pub
	    if pub.nil?
	          pub = Publication.create(
	          	active: true,
	            title: title,
	            year: year,
	            issn: issn,
	            pages: pages,
          		publication_type: type,
	            sciencewire_id: sciencewire_id,
	            pmid: pmid)
	    end
	    # add the new contribution for this harvest.  
	    # first_or_create so we don't override a previous status for this pairing
	    Contribution.where(:author_id => author.id, publication_id: pub.id).first_or_create(
	      	cap_profile_id: author.cap_profile_id,
	    	status: status,
	    	visibility: visibility, 
	    	featured: featured)
	    # finally build or rebuild the pub_hash from the sciencewire and pubmed data
	    pub.build_from_sciencewire_hash(pub_hash)
	    pub.sync_publication_hash_and_db
	end


	def self.save_or_update_sw_source_record(sciencewire_id, pmid, incoming_sw_xml_as_string)
	    
	    existing_sw_source_record = SciencewireSourceRecord.where(
	      :sciencewire_id => sciencewire_id).first
	    if existing_sw_source_record.nil?
	    	new_source_fingerprint = get_source_fingerprint(incoming_sw_xml_as_string)
	        SciencewireSourceRecord.create(
	                        :sciencewire_id => sciencewire_id,
	                        :source_data => incoming_sw_xml_as_string,
	                        :is_active => true,
	                        source_fingerprint: new_source_fingerprint,
	                        :pmid => pmid
	        )
	    #elsif existing_sw_source_record.source_fingerprint != new_source_fingerprint      
	     #   existing_sw_source_record.update_attributes(
	     #     pmid: pmid,
	     #     source_data: incoming_sw_xml_as_string,
	     #     is_active: true,
	     #     source_fingerprint: new_source_fingerprint  
	     #    )           
	    end
	end

	def self.get_source_fingerprint(sw_record_doc)
	  Digest::SHA2.hexdigest(sw_record_doc)
	end

	def self.source_data_has_changed?(existing_sw_source_record, incoming_sw_source_doc)
	  existing_sw_source_record.source_fingerprint != get_source_fingerprint(incoming_sw_source_doc)
	end
	
	def self.convert_sw_publication_doc_to_hash(publication)

	    record_as_hash = Hash.new
	    
	    record_as_hash[:provenance] = Settings.sciencewire_source
	    record_as_hash[:pmid] = publication.xpath("PMID").text unless publication.xpath("PMID").blank?
	    record_as_hash[:sw_id] = publication.xpath("PublicationItemID").text
	    record_as_hash[:title] = publication.xpath("Title").text unless publication.xpath("Title").blank?
	    record_as_hash[:abstract_restricted] = publication.xpath("Abstract").text unless publication.xpath("Abstract").blank?
	    record_as_hash[:author] = publication.xpath('AuthorList').text.split('|').collect{|author| {name: author}}
	    
	    record_as_hash[:year] = publication.xpath('PublicationYear').text unless publication.xpath("PublicationYear").blank?
	    record_as_hash[:date] = publication.xpath('PublicationDate').text unless publication.xpath("PublicationDate").blank?
	    
	    record_as_hash[:authorcount] = publication.xpath("AuthorCount").text unless publication.xpath("AuthorCount").blank?
	    
	    record_as_hash[:keywords_sw] = publication.xpath('KeywordList').text.split('|') unless publication.xpath("KeywordList").blank?
	    record_as_hash[:documenttypes_sw] = publication.xpath("DocumentTypeList").text.split('|')
	    sul_document_type = lookup_sw_doc_type(record_as_hash[:documenttypes_sw])
	    record_as_hash[:type] = sul_document_type

	    record_as_hash[:documentcategory_sw] = publication.xpath("DocumentCategory").text unless publication.xpath("DocumentCategory").blank?
	    record_as_hash[:publicationimpactfactorlist_sw] = publication.xpath('PublicationImpactFactorList').text.split('|')  unless publication.xpath("PublicationImpactFactorList").blank?
	    record_as_hash[:publicationcategoryrankinglist_sw] = publication.xpath('PublicationCategoryRankingList').text.split('|')  unless publication.xpath("PublicationCategoryRankingList").blank?
	    record_as_hash[:numberofreferences_sw] = publication.xpath("NumberOfReferences").text unless publication.xpath("NumberOfReferences").blank?
	    record_as_hash[:timescited_sw_retricted] = publication.xpath("TimesCited").text unless publication.xpath("TimesCited").blank?
	    record_as_hash[:timenotselfcited_sw] = publication.xpath("TimesNotSelfCited").text unless publication.xpath("TimesNotSelfCited").blank?
	    record_as_hash[:authorcitationcountlist_sw] = publication.xpath("AuthorCitationCountList").text unless publication.xpath("AuthorCitationCountList").blank?
	    record_as_hash[:rank_sw] =  publication.xpath('Rank').text unless publication.xpath("Rank").blank?
	    record_as_hash[:ordinalrank_sw] = publication.xpath('OrdinalRank').text unless publication.xpath("OrdinalRank").blank?
	    record_as_hash[:normalizedrank_sw] = publication.xpath('NormalizedRank').text unless publication.xpath("NormalizedRank").blank?
	    record_as_hash[:newpublicationid_sw] = publication.xpath('NewPublicationItemID').text unless publication.xpath("NewPublicationItemID").blank?
	    record_as_hash[:isobsolete_sw] = publication.xpath('IsObsolete').text unless publication.xpath("IsObsolete").blank?
	    
	    record_as_hash[:publisher] =  publication.xpath('CopyrightPublisher').text unless publication.xpath("CopyrightPublisher").blank?
	    record_as_hash[:city] = publication.xpath('CopyrightCity').text unless publication.xpath("CopyrightCity").blank?
	    record_as_hash[:stateprovince] = publication.xpath('CopyrightStateProvince').text unless publication.xpath("CopyrightStateProvince").blank?
	    record_as_hash[:country] = publication.xpath('CopyrightCountry').text unless publication.xpath("CopyrightCountry").blank?
	    record_as_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?

	    identifiers = Array.new
	    identifiers << {:type =>'PMID', :id => publication.at_xpath("PMID").text, :url => 'http://www.ncbi.nlm.nih.gov/pubmed/' + publication.xpath("PMID").text } unless publication.at_xpath("PMID").nil?
	    identifiers << {:type => 'WoSItemID', :id => publication.at_xpath("WoSItemID").text, :url => 'http://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info:ut/' + publication.xpath("WoSItemID").text} unless publication.at_xpath("WoSItemID").nil?
	    identifiers << {:type => 'PublicationItemID', :id => publication.at_xpath("PublicationItemID").text} unless publication.at_xpath("PublicationItemID").nil?
	    
	    # an issn is for either a journal or a book series (international standard series number)
	    issn = {:type => 'issn', :id => publication.xpath('ISSN').text, :url => 'http://searchworks.stanford.edu/?search_field=advanced&number=' + publication.xpath('ISSN').text} unless publication.xpath('ISSN').blank?
	    record_as_hash[:issn] = publication.xpath('ISSN').text unless publication.xpath('ISSN').blank?
	    if sul_document_type == Settings.sul_doc_types.inproceedings
	      conference_hash = {}
	      conference_hash[:startdate] = publication.xpath('ConferenceStartDate').text unless publication.xpath("ConferenceStartDate").blank?
	      conference_hash[:enddate] = publication.xpath('ConferenceEndDate').text unless publication.xpath("ConferenceEndDate").blank?
	      conference_hash[:city] = publication.xpath('ConferenceCity').text unless publication.xpath("ConferenceCity").blank?
	      conference_hash[:statecountry] = publication.xpath('ConferenceStateCountry').text unless publication.xpath("ConferenceStateCountry").blank?
	      record_as_hash[:conference] = conference_hash unless conference_hash.empty?
	      
	    elsif sul_document_type == Settings.sul_doc_types.book
	      record_as_hash[:booktitle] = publication.xpath('PublicationSourceTitle').text unless publication.xpath("PublicationSourceTitle").blank?
	      record_as_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath("Pagination").blank?
	      identifiers << {:type => 'doi', :id => publication.xpath('DOI').text, :url => 'http://dx.doi.org/' + publication.xpath('DOI').text} unless publication.xpath('DOI').blank?
	      
	    end

	    if sul_document_type == Settings.sul_doc_types.article || (sul_document_type == Settings.sul_doc_types.inproceedings && ! publication.xpath('Issue').blank?)
	      journal_hash = {}   
	      journal_hash[:name] = publication.xpath('PublicationSourceTitle').text unless publication.xpath('PublicationSourceTitle').blank?
	      journal_hash[:volume] = publication.xpath('Volume').text unless publication.xpath('Volume').blank?
	      journal_hash[:issue] = publication.xpath('Issue').text unless publication.xpath('Issue').blank?
	      journal_hash[:articlenumber] = publication.xpath('ArticleNumber').text unless publication.xpath('ArticleNumber').blank?
	      journal_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?
	      journal_identifiers = Array.new
	      journal_identifiers << {:type => 'issn', :id => publication.xpath('ISSN').text, :url => 'http://searchworks.stanford.edu/?search_field=advanced&number=' + publication.xpath('ISSN').text} unless publication.xpath('ISSN').blank?
	      journal_identifiers << {:type => 'doi', :id => publication.xpath('DOI').text, :url => 'http://dx.doi.org/' + publication.xpath('DOI').text} unless publication.xpath('DOI').blank?
	      journal_hash[:identifier] = journal_identifiers
	      record_as_hash[:journal] = journal_hash
	    end
	    
	    unless issn.blank? || publication.xpath('Issue').blank? || sul_document_type == Settings.sul_doc_types.article
	        book_series_hash = {}
	        book_series_hash[:identifier] = [issn] 
	        book_series_hash << publication.xpath('PublicationSourceTitle').text unless publication.xpath('PublicationSourceTitle').blank?
	        book_series_hash << publication.xpath('Volume').text unless publication.xpath('Volume').blank?
	        record_as_hash[:series] = book_series_hash 
	    end
	    record_as_hash[:identifier] = identifiers
	    record_as_hash
	  end


	def self.lookup_sw_doc_type(doc_type_list)  
	    if !(@@sw_conference_proceedings_type_strings & doc_type_list).empty?
	      type =  Settings.sul_doc_types.inproceedings
	    elsif !(@@sw_book_type_strings & doc_type_list).empty?
	      type =  Settings.sul_doc_types.book
	    else
	      type =  Settings.sul_doc_types.article
	    end
	    type
	end

	def self.query_sciencewire_for_publication(first_name, last_name, middle_name, title, year, max_rows)
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
	    	pub_hash = convert_sw_publication_doc_to_hash(sw_xml_doc)
	    	Publication.update_formatted_citations(pub_hash)
	    	result << pub_hash

	  end 

	  result

	end

	def self.pull_records_from_sciencewire_for_pmids(pmid_list)

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

	def self.query_sciencewire(xml_query)

	  wrapped_xml_query = '<?xml version="1.0"?>
	          <ScienceWireQueryXMLParameter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	            <xmlQuery>' + xml_query + '</xmlQuery>
	          </ScienceWireQueryXMLParameter>'

	    http = Net::HTTP.new("sciencewirerest.discoverylogic.com", 443)
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	    http.ssl_version = :SSLv3
	    request = Net::HTTP::Post.new("/PublicationCatalog/PublicationQuery?format=xml")
	    request["LicenseID"] = "***REMOVED***"
	    request["Host"] = "sciencewirerest.discoverylogic.com"
	    request["Connection"] = "Keep-Alive"
	    request["Expect"] = "100-continue"
	    request["Content-Type"] = "text/xml"
	    

	    request.body = wrapped_xml_query

	    http.start

	    response = http.request(request)
	    response_body = response.body
	    xml_doc = Nokogiri::XML(response_body)
	    queryId = xml_doc.xpath('//queryID').text

	    fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationQuery/" + queryId + "?format=xml&v=version/3&page=0&pageSize=2147483647")
	    fullPubsRequest["Content_Type"] = "text/xml"
	    fullPubsRequest["LicenseID"] = "***REMOVED***"
	    fullPubsRequest["Host"] = "sciencewirerest.discoverylogic.com"
	    fullPubsRequest["Connection"] = "Keep-Alive"

	    fullPubResponse = http.request(fullPubsRequest)
	    xml_doc = Nokogiri::XML(fullPubResponse.body)
	    http.finish
	    xml_doc
	   
	  end

	  


	  def self.get_sw_guesses(last_name, first_name, middle_name, email_list, seed_list)


	    http = Net::HTTP.new("sciencewirerest.discoverylogic.com", 443)
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	    http.ssl_version = :SSLv3
	    request = Net::HTTP::Post.new("/PublicationCatalog/MatchedPublicationItemIdsForAuthor?format=xml")
	    request["LicenseID"] = "***REMOVED***"
	    request["Host"] = "sciencewirerest.discoverylogic.com"
	    request["Connection"] = "Keep-Alive"
	    request["Expect"] = "100-continue"
	    request["Content-Type"] = "text/xml"

	    bod = '<?xml version="1.0"?>
	<PublicationAuthorMatchParameters xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	  <Authors>
	    <Author>
	      <LastName>' + last_name + '</LastName>
	      <FirstName>' + first_name + '</FirstName>
	      <MiddleName>' + middle_name + '</MiddleName>
	      <City>Stanford</City>
	      <State>CA</State>
	      <Country>USA</Country>
	    </Author>
	  </Authors>
	  <DocumentCategory>Journal Document</DocumentCategory>' 

	    unless seed_list.blank?
	      bod << '<PublicationItemIds>'
	      bod << seed_list.collect { |pubId| "<int>#{pubId}</int>"}.join
	      bod << '</PublicationItemIds>'
	    end

	    unless email_list.blank?
	      bod << '<Emails>'
	      bod <<   email_list.collect { |email| "<string>#{email}</string>"}.join
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
	    items = xml_doc.xpath('/ArrayOfItemMatchResult/ItemMatchResult/PublicationItemID').collect { |itemId| itemId.text}.join(',')
	 #   puts "sciencewire guesses at pub ids for given author: " + items.to_s
	    fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationItems?format=xml&publicationItemIDs=" + items)
	    fullPubsRequest["Content-Type"] = "text/xml"
	    fullPubsRequest["LicenseID"] = "***REMOVED***"
	    fullPubsRequest["Host"] = "sciencewirerest.discoverylogic.com"
	    fullPubsRequest["Connection"] = "Keep-Alive"

	    fullPubResponse = http.request(fullPubsRequest).body
	  	#puts fullPubResponse.to_s
	    xml_doc = Nokogiri::XML(fullPubResponse)
	    #http.finish
	    xml_doc

	    # puts xml_result
	    # puts "Time to run sw query in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)

	  end


	
end
