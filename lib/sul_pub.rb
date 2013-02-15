require 'nokogiri'

module SulPub

	include ActionView::Helpers::DateHelper

	def create_new_pubs_and_contributions_for_pmids(pmids, contribs)
		mesh_values_for_pmids = get_mesh_from_pubmed(pmids)
		sw_records_doc = pull_records_from_sciencewire(pmids)
    	sw_records_doc.xpath('//PublicationItem').each do |publication|
    		ActiveRecord::Base.transaction do	
    			#start_time = Time.now
    			pub_hash = convert_sw_publication_doc_to_hash(publication)	
    			#puts "converting one sciencewire record to hash took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
		
    			new_pub = Publication.create(active: true, human_readable_title: pub_hash[:title])
    			pub_hash[:sulpubid] = new_pub.id
    			pub_hash[:article_identifiers] << {:type => 'SULPubId', :id => new_pub.id.to_s, :url => 'http://sulcap.stanford.edu/publications/' + new_pub.id.to_s}
    			pub_hash[:mesh_headings] = mesh_values_for_pmids[pub_hash[:pmid]]

    			pub_hash[:last_updated] = new_pub.updated_at
    			add_formatted_citations(pub_hash)
    			add_contribution_pair(pub_hash, contribs)
    			# publication.save && publication.contributions.create(:person => some_person_object, :status => contribution[:status], :hightlight_ind => contribution[:highlight_ind])
    			# also save publication identifiers
    			# also need to save the sw records somewhere local.
    			new_pub.json = generate_json_for_pub(pub_hash)
    			new_pub.xml = generate_xml_for_pub(pub_hash)
    			new_pub.save
			end		
    	end
	end

def add_contribution_pair(pub_hash, contributions)
		pmid = pub_hash[:pmid]
		contribution = contributions[pmid]
		cap_profile_id = contribution['faculty_id']
		contribution_status = contribution['status']
		should_highlight = contribution['highlight_ind']
		author_id = Author.create(cap_profile_id: cap_profile_id).id
		PopulationMembership.create(author_id: author_id, cap_profile_id: cap_profile_id, population_name: 'cap')
		Contribution.create(author_id: author_id, 
			cap_profile_id: cap_profile_id,
			publication_id: pub_hash[:sulpubid], 
			confirmed_status: contribution_status,
			highlight_ind: should_highlight)
		pub_hash[:contributions] = [
	 		{:cap_profile_id => cap_profile_id, 
	 			:sul_author_id => author_id, 
	 			:status => contribution_status, 
	 			:highlight_ind => should_highlight}
    	]
	end

	def convert_sw_publication_doc_to_hash(publication)

		record_as_hash = Hash.new
		record_as_hash[:pmid] = publication.xpath("PMID").text
	    record_as_hash[:title] = publication.xpath("Title").text
	    record_as_hash[:the_abstract] = publication.xpath("Abstract").text
	    record_as_hash[:authors] = publication.xpath('AuthorList').text.split('|')
	    record_as_hash[:keywords] = publication.xpath('KeywordList').text.split('|')
	    record_as_hash[:documentTypes] = publication.xpath("DocumentTypeList").text.split('|')
	    record_as_hash[:documentCategory] = publication.xpath("DocumentCategory").text
	    record_as_hash[:numberOfRefernces] = publication.xpath("NumberOfReferences").text
	    record_as_hash[:timesCited] = publication.xpath("TimesCited").text
	    record_as_hash[:timesNotSelfCited] = publication.xpath("TimesNotSelfCited").text
	    record_as_hash[:article_identifiers] = [
	        {:type =>'PMID', :id => publication.xpath("PMID").text, :url => 'http://www.ncbi.nlm.nih.gov/pubmed/' + publication.xpath("PMID").text }, 
	        {:type => 'WoSItemID', :id => publication.xpath("WoSItemID").text, :url => 'http://wosuri/' + publication.xpath("WoSItemID").text}, 
	        {:type => 'PublicationItemID', :id => publication.xpath("PublicationItemID").text, :url => 'http://sciencewireURI/' + publication.xpath("PublicationItemID").text},

	    ]
	    # the journal info
	    record_as_hash[:publicationTitle] = publication.xpath('PublicationSourceTitle').text
	    record_as_hash[:publicationVolume] = publication.xpath('Volume').text
	    record_as_hash[:publicationIssue] = publication.xpath('Issue').text
	    record_as_hash[:publicationPagination] = publication.xpath('Pagination').text
	    record_as_hash[:publicationDate] = publication.xpath('PublicationDate').text
	    record_as_hash[:publicationYear] = publication.xpath('PublicationYear').text
	    record_as_hash[:publicationImpactFactor] = publication.xpath('PublicationImpactFactor').text
	    record_as_hash[:publicationSubjectCategories] = publication.xpath('PublicationSubjectCategoryList').text.split('|')
	    record_as_hash[:publicationIdentifiers] = [
	        {:type => 'issn', :id => publication.xpath('ISSN').text, :url => 'http://searchworks.stanford.edu/?search_field=advanced&number=' + publication.xpath('ISSN').text},
	        {:type => 'doi', :id => publication.xpath('DOI').text, :url => 'http://dx.doi.org/' + publication.xpath('DOI').text}
	    ]
	    record_as_hash[:publicationConferenceStartDate] = publication.xpath('ConferenceStartDate').text
	    record_as_hash[:publicationConferenceEndDate] = publication.xpath('ConferenceEndDate').text
	    record_as_hash[:rank] =  publication.xpath('Rank').text
	    record_as_hash[:ordinalRank] = publication.xpath('OrdinalRank').text
	    record_as_hash[:normalizedRank] = publication.xpath('NormalizedRank').text
	    record_as_hash[:newPublicationId] = publication.xpath('NewPublicationItemID').text
	    record_as_hash[:isObsolete] = publication.xpath('IsObsolete').text
	    record_as_hash[:copyrightPublisher] =  publication.xpath('CopyrightPublisher').text
	    record_as_hash[:copyrightCity] = publication.xpath('CopyrightCity').text
		
		record_as_hash
	end

    

	def generate_json_for_pub(pub_hash)

	    jsonString = Jbuilder.encode do |json| 
	        json.identifier(pub_hash[:article_identifiers]) do  |identifier|        
	                    json.(identifier, :id, :type, :url)      
	        end
	        json.title pub_hash[:title]
	        json.abstract pub_hash[:the_abstract]
	        json.keywords pub_hash[:keywords]
	        json.author pub_hash[:authors] do | author |
	            json.name author
	        end
	       # json.authorsAnded
	        json.documenttypes pub_hash[:documentTypes]
	        json.category pub_hash[:documentCategory]
	        json.timescited pub_hash[:timesCited]
	        json.timesnotselfcited pub_hash[:timesNotSelfCited]
	        json.rank pub_hash[:rank]
	        json.ordinalrank pub_hash[:ordinalRank]
	        json.normalizedrank pub_hash[:normalizedRank]
	        json.newpublicationid pub_hash[:newPublicationId]
	        json.isobsolete pub_hash[:isObsolete]
	        json.publisher pub_hash[:copyrightPublisher]
	        json.address pub_hash[:copyrightCity]
	        json.mesh(pub_hash[:mesh_headings]) do | heading |
	            json.descriptor(heading[:descriptor])  do |descriptor|
	                json.(descriptor, :major, :name)
	            end
	            json.qualifier(heading[:qualifier]) do |qualifier|
	                json.(qualifier, :major, :name)
	            end
	        end
	        json.journal do | json |
	            json.name pub_hash[:publicationTitle]
	            json.volume pub_hash[:publicationVolume]
	            json.issue pub_hash[:publicationIssue]
	            json.pages pub_hash[:publicationPagination]
	            json.date pub_hash[:publicationDate]
	            json.year pub_hash[:publicationYear]
	            json.publicationimpactfactor pub_hash[:publicationImpactFactor]
	            json.subjectcategories pub_hash[:publicationSubjectCategories]
	            json.identifer(pub_hash[:publicationIdentifiers]) do | identifier |
	                json.(identifier, :id, :type, :url)
	            end
	            json.conferencestartdate pub_hash[:publicationConferenceStartDate]
	            json.conferenceenddate pub_hash[:publicationConferenceEndDate]
	        end
	        json.contributions(pub_hash[:contributions]) do | contribution |
	            json.(contribution, :sul_author_id, :cap_profile_id, :status, :highlight_ind)
	        end
	        json.chicago pub_hash[:chicago_citation]
	        json.apa pub_hash[:apa_citation]
	        json.mla pub_hash[:mla_citation]
	        json.lastupdated pub_hash[:last_updated]

	    end
    end

    def generate_xml_for_pub(pub_hash)
		xmlbuilder = Nokogiri::XML::Builder.new do |newPubDoc|
		
			newPubDoc.publication {
                
				newPubDoc.title pub_hash[:title]
				pub_hash[:authors].each do | authorName | 
					newPubDoc.author {
						newPubDoc.name pub_hash[:authorName]
					}
				end
				newPubDoc.abstract_ pub_hash[:the_abstract]
				pub_hash[:keywords].each do | keyword |
					newPubDoc.keyword keyword
				end
				pub_hash[:documentTypes].each do | docType |
					newPubDoc.type docType
				end
				newPubDoc.category pub_hash[:documentCategory]
                newPubDoc.journal {
                    newPubDoc.title pub_hash[:publicationTitle]
                }

               # also add the last_update_at_source, last_retrieved_from_source, 
			}
		

		end
	xmlbuilder.to_xml
    
  end

  	def add_formatted_citations(pub_hash)
  		#[{"id"=>"Gettys90", "type"=>"article-journal", "author"=>[{"family"=>"Gettys", "given"=>"Jim"}, {"family"=>"Karlton", "given"=>"Phil"}, {"family"=>"McGregor", "given"=>"Scott"}], "title"=>"The {X} Window System, Version 11", "container-title"=>"Software Practice and Experience", "volume"=>"20", "issue"=>"S2", "abstract"=>"A technical overview of the X11 functionality.  This is an update of the X10 TOG paper by Scheifler \\& Gettys.", "issued"=>{"date-parts"=>[[1990]]}}]
		chicago_csl_file = Rails.root.join('app', 'data', 'chicago-author-date.csl')
  	
  		authors_for_citeproc = []
		pub_hash[:authors].each do |author| 
    		last_name = ""
    		rest_of_name = ""
    		author.split(',').each_with_index do |name_part, index|
        		if index == 0 
            		last_name = name_part
        		elsif name_part.length == 1
            		rest_of_name << ' ' << name_part << '.'
        		elsif name_part.length > 1
            		rest_of_name << ' ' << name_part
        		end
    		end
    		authors_for_citeproc << {"family" => last_name, "given" => rest_of_name}
		end

		cit_data = [{"id" => "test89", 
			"type"=>"article-journal", 
			"author"=>authors_for_citeproc,  
			"title"=>pub_hash[:title], 
			"container-title"=>pub_hash[:publicationTitle], 
			"volume"=>pub_hash[:publicationVolume], 
			"issue"=>pub_hash[:publicationIssue], 
			"abstract"=>pub_hash[:the_abstract], 
			"issued"=>{"date-parts"=>[[pub_hash[:publicationYear]]]}
			}]

		# chicago_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/chicago-author-date.csl', :format => 'html')
		# apa_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/apa.csl', :format => 'html')
		# mla_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/mla.csl', :format => 'html')
		pub_hash[:apa_citation] = CiteProc.process(cit_data, :style => :apa, :format => 'html')
		pub_hash[:mla_citation] = CiteProc.process(cit_data, :style => :mla, :format => 'html')
		pub_hash[:chicago_citation] = CiteProc.process(cit_data, :style => chicago_csl_file, :format => 'html')
  	end

	
	


	def pull_records_from_sciencewire(pmid_list)

     	pmidValuesAsXML = pmid_list.collect { |pmid| "&lt;Value&gt;#{pmid}&lt;/Value&gt;"}.join
     	#start_time = Time.now
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
		bod = '<?xml version="1.0"?>
					<ScienceWireQueryXMLParameter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
					  <xmlQuery>&lt;query xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"&gt;
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
					  &lt;MaximumRows&gt;500&lt;/MaximumRows&gt;
					&lt;/query&gt;</xmlQuery>
					</ScienceWireQueryXMLParameter>'
					
					request.body = bod
		response = http.request(request)
		#puts "ScienceWire pubmed conversion call took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
		#start_time = Time.now
		xml_doc = Nokogiri::XML(response.body)
		#puts xml_doc.to_xml
		queryId = xml_doc.xpath('//queryID').text
    
		fullPubsRequest = Net::HTTP::Get.new("/PublicationCatalog/PublicationQuery/" + queryId + "?format=xml&v=version/3&page=0&pageSize=2147483647")
		fullPubsRequest["Content_Type"] = "text/xml"
		fullPubsRequest["LicenseID"] = "***REMOVED***"
		fullPubsRequest["Host"] = "sciencewirerest.discoverylogic.com"
		fullPubsRequest["Connection"] = "Keep-Alive"

		fullPubResponse = http.request(fullPubsRequest)
		#puts "ScienceWire full record retrieval call took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
		#start_time = Time.now
		Nokogiri::XML(fullPubResponse.body)
		#puts "Parsing ScienceWire results took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
		
	end

	def get_mesh_from_pubmed(pmid_list)
		mesh_values_for_all_records = Hash.new
		pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}"}.join
		#start_time = Time.now
		http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")	
		request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
		request.body = pmidValuesForPost
		#puts "PubMed call took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
		#start_time = Time.now
		Nokogiri::XML(http.request(request).body).xpath('//PubmedArticle').each do |publication|
			pmid = publication.xpath('MedlineCitation/PMID').text
			mesh_headings_for_record = []
			publication.xpath('MedlineCitation/MeshHeadingList/MeshHeading').each do |mesh_heading|
				descriptors = []
				qualifiers = []
				mesh_heading.xpath('DescriptorName').each do |descriptor_name|
					descriptors << {:major => descriptor_name.attr('MajorTopicYN'), :name => descriptor_name.text}			
				end
				mesh_heading.xpath('QualifierName').each do |qualifier_name|
					qualifiers << {:major => qualifier_name.attr('MajorTopicYN'), :name => qualifier_name.text}		
				end
				mesh_headings_for_record << { :descriptor => descriptors, :qualifier => qualifiers }
			end
			mesh_values_for_all_records[pmid] = mesh_headings_for_record
		end
		#puts "extracting mesh from pubmed results took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
		
		mesh_values_for_all_records
	end



end  #module end


