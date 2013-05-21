require 'nokogiri'

class PubmedSourceRecord < ActiveRecord::Base
  attr_accessible :is_active, :lock_version, :pmid, :source_data, :source_fingerprint
 # validates_uniqueness_of :pmid
  validates_presence_of :source_data

  	def self.get_pub_by_pmid(pmid) 
  		pubmed_pub_hash = PubmedSourceRecord.get_pubmed_hash_for_pmid(pmid)
  		unless pubmed_pub_hash.nil?
            pub = Publication.new(
              active: true,
              title: pubmed_pub_hash[:title],
              year: pubmed_pub_hash[:year],
              pmid: pmid)  
            pub.build_from_pubmed_hash(pubmed_pub_hash)  
        end
  	end

  	def self.get_pubmed_hash_for_pmid(pmid)
  		pubmed_source_record = get_pubmed_source_record_for_pmid(pmid)
  		unless pubmed_source_record.nil?
  			pubmed_source_record.get_source_as_hash
  		end
  	end

  	def self.get_pubmed_source_record_for_pmid(pmid)
  		PubmedSourceRecord.where(pmid: pmid).first || PubMedSourceRecord.get_pubmed_record_from_pubmed(pmid)
  	end

  	def self.get_pubmed_record_from_pubmed(pmid)
  		get_and_store_records_from_pubmed([pmid])
  		PubmedSourceRecord.where[pmid: pmid].first
  	end

	def self.get_and_store_records_from_pubmed(pmids)
		pmidValuesForPost = pmids.collect { |pmid| "&id=#{pmid}"}.join
		http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")	
		request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
		request.body = pmidValuesForPost
		http.start
		the_incoming_xml = http.request(request).body
		http.finish
		count = 0
		source_records = []
		
		Nokogiri::XML(the_incoming_xml).xpath('//PubmedArticle').each do |pub_doc|
	  		pmid = pub_doc.xpath('MedlineCitation/PMID').text    
	        begin        
	          	count += 1
	          	pmids.delete(pmid)
	          	source_records << PubmedSourceRecord.new(
                      :pmid => pmid,
	                  :source_data => pub_doc.to_xml,
	                  :is_active => true,
	                  :source_fingerprint => Digest::SHA2.hexdigest(pub_doc))
		    rescue Exception => e  
	          puts e.message  
	          puts e.backtrace.inspect  
	          puts "the offending pmid: " + pmid.to_s
	        end
	        
	    end
    	puts source_records.length.to_s + " records about to be created."
    	PubmedSourceRecord.import source_records 
    	puts count.to_s + " pmids were processed. "
    	puts pmids.length.to_s + " pmids weren't processed: "

	end

	def extract_abstract_from_pubmed_record(publication)
		publication.xpath('MedlineCitation/Article/Abstract/AbstractText').text
	end

	def extract_mesh_headings_from_pubmed_record(publication)
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
	      mesh_headings_for_record
	end

	def get_source_as_hash 
		convert_pubmed_publication_doc_to_hash(Nokogiri::XML(source_data).xpath('//PubmedArticle'))
	end

	def convert_pubmed_publication_doc_to_hash_old(publication)

	    record_as_hash = Hash.new
	    pmid = publication.xpath('//MedlineCitation/PMID').text 
	    
	    abstract = extract_abstract_from_pubmed_record(publication)
	    mesh_headings = extract_mesh_headings_from_pubmed_record(publication)

	    record_as_hash[:provenance] = Settings.pubmed_source
	    record_as_hash[:pmid] = pmid

	    record_as_hash[:title] = publication.xpath("//MedlineCitation/Article/ArticleTitle").text unless publication.xpath("//MedlineCitation/Article/ArticleTitle").blank?
	    record_as_hash[:abstract] = abstract unless abstract.blank?
	    
	    author_array = []
	    publication.xpath('//MedlineCitation/Article/AuthorList/Author').each do |author|
	    	author_hash = {}
	    	author_hash[:lastname] = author.xpath("LastName").text
			initials = author.xpath("Initials").text.scan(/./)
	    	author_hash[:middlename] = initials[1] unless initials.length < 2
	    	author_hash[:firstname] = initials[0] unless initials.length < 1
	    	author_array << author_hash
	    end
	    record_as_hash[:author] = author_array

	    record_as_hash[:mesh_headings] = mesh_headings unless mesh_headings.blank?
	    record_as_hash[:year] = publication.xpath('//MedlineCitation/Article/Journal/JournalIssue/PubDate/Year').text unless publication.xpath("//MedlineCitation/Article/Journal/JournalIssue/PubDate/Year").blank?
	    
	     record_as_hash[:type] = Settings.sul_doc_types.article

	    #record_as_hash[:publisher] =  publication.xpath('//MedlineCitation/Article/').text unless publication.xpath("//MedlineCitation/Article/").blank?
	    #record_as_hash[:city] = publication.xpath('//MedlineCitation/Article/').text unless publication.xpath("//MedlineCitation/Article/").blank?
	    #record_as_hash[:stateprovince] = publication.xpath('//MedlineCitation/Article/').text unless publication.xpath("//MedlineCitation/Article/").blank?
	    record_as_hash[:country] = publication.xpath('//MedlineCitation/MedlineJournalInfo/Country').text unless publication.xpath("//MedlineCitation/MedlineJournalInfo/Country").blank?

		record_as_hash[:pages] = publication.xpath('//MedlineCitation/Article/Pagination/MedlinePgn').text unless publication.xpath("//MedlineCitation/Article/Pagination/MedlinePgn").blank?
	      
    	journal_hash = {}   
		journal_hash[:name] = publication.xpath('//MedlineCitation/Article/Journal/Title').text unless publication.xpath('//MedlineCitation/Article/Journal/Title').blank?
		journal_hash[:volume] = publication.xpath('//MedlineCitation/Article/Journal/JournalIssue/Volume').text unless publication.xpath('//MedlineCitation/Article/Journal/JournalIssue/Volume').blank?
		journal_hash[:issue] = publication.xpath('//MedlineCitation/Article/Journal/JournalIssue/Issue').text unless publication.xpath('//MedlineCitation/Article/Journal/JournalIssue/Issue').blank?
		 # journal_hash[:articlenumber] = publication.xpath('ArticleNumber') unless publication.xpath('ArticleNumber').blank?
		#  journal_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?
		journal_identifiers = Array.new
		journal_identifiers << {:type => 'issn', :id => publication.xpath('//MedlineCitation/Article/Journal/ISSN').text, :url => 'http://searchworks.stanford.edu/?search_field=advanced&number=' + publication.xpath('//MedlineCitation/Article/Journal/ISSN').text} unless publication.xpath('//MedlineCitation/Article/Journal/ISSN').nil?
		journal_hash[:identifier] = journal_identifiers
		record_as_hash[:journal] = journal_hash
    
	    record_as_hash[:identifier] = [{:type =>'PMID', :id => pmid, :url => 'http://www.ncbi.nlm.nih.gov/pubmed/' + pmid } ]
	    #puts "the record as hash"
	    #puts record_as_hash.to_s
	    record_as_hash
  end

def convert_pubmed_publication_doc_to_hash(publication)

	    record_as_hash = Hash.new
	    pmid = publication.xpath('MedlineCitation/PMID').text 
	    
	    abstract = extract_abstract_from_pubmed_record(publication)
	    mesh_headings = extract_mesh_headings_from_pubmed_record(publication)

	    record_as_hash[:provenance] = Settings.pubmed_source
	    record_as_hash[:pmid] = pmid

	    record_as_hash[:title] = publication.xpath("MedlineCitation/Article/ArticleTitle").text unless publication.xpath("MedlineCitation/Article/ArticleTitle").blank?
	    record_as_hash[:abstract] = abstract unless abstract.blank?
	    
	    author_array = []
	    publication.xpath('MedlineCitation/Article/AuthorList/Author').each do |author|
	    	author_hash = {}
	    	author_hash[:lastname] = author.xpath("LastName").text
			initials = author.xpath("Initials").text.scan(/./)
	    	author_hash[:middlename] = initials[1] unless initials.length < 2
	    	author_hash[:firstname] = initials[0] unless initials.length < 1
	    	author_array << author_hash
	    end
	    record_as_hash[:author] = author_array

	    record_as_hash[:mesh_headings] = mesh_headings unless mesh_headings.blank?
	    record_as_hash[:year] = publication.xpath('MedlineCitation/Article/Journal/JournalIssue/PubDate/Year').text unless publication.xpath("MedlineCitation/Article/Journal/JournalIssue/PubDate/Year").blank?
	    
	     record_as_hash[:type] = Settings.sul_doc_types.article

	    #record_as_hash[:publisher] =  publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
	    #record_as_hash[:city] = publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
	    #record_as_hash[:stateprovince] = publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
	    record_as_hash[:country] = publication.xpath('MedlineCitation/MedlineJournalInfo/Country').text unless publication.xpath("MedlineCitation/MedlineJournalInfo/Country").blank?

		record_as_hash[:pages] = publication.xpath('MedlineCitation/Article/Pagination/MedlinePgn').text unless publication.xpath("MedlineCitation/Article/Pagination/MedlinePgn").blank?
	      
    	journal_hash = {}   
		journal_hash[:name] = publication.xpath('MedlineCitation/Article/Journal/Title').text unless publication.xpath('MedlineCitation/Article/Journal/Title').blank?
		journal_hash[:volume] = publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').text unless publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').blank?
		journal_hash[:issue] = publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').text unless publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').blank?
		 # journal_hash[:articlenumber] = publication.xpath('ArticleNumber') unless publication.xpath('ArticleNumber').blank?
		#  journal_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?
		journal_identifiers = Array.new
		journal_identifiers << {:type => 'issn', :id => publication.xpath('MedlineCitation/Article/Journal/ISSN').text, :url => 'http://searchworks.stanford.edu/?search_field=advanced&number=' + publication.xpath('MedlineCitation/Article/Journal/ISSN').text} unless publication.xpath('MedlineCitation/Article/Journal/ISSN').nil?
		journal_hash[:identifier] = journal_identifiers
		record_as_hash[:journal] = journal_hash
    
	    record_as_hash[:identifier] = [{:type =>'PMID', :id => pmid, :url => 'http://www.ncbi.nlm.nih.gov/pubmed/' + pmid } ]
	    #puts "the record as hash"
	    #puts record_as_hash.to_s
	    record_as_hash
  end

end

=begin
	def getPubMedForAllIds
		filename = Rails.root.join('app', 'data', 'CAP_author_pubs_sample.csv')
		CSV.foreach(filename, :headers => true) do |row|

			line = row.parse_csv
			contribution = {
				:profile_id => line[1]
				:publication_id = line[0]
				:status = line[4]
				:highlight = line[5]
			}
			contribution_mappings << contribution
			pmidList << line[0]
			if pmidList.count == 200
				pmids
				sw_records = get_sciencewirecords(pmids)
				pubmed_records = get_pubmed_records(pmids)
				create_new_sul_records(sw_records, pubmed_records, contribution_mappings)

			
	end


	def ingestCapContributions
		filename = Rails.root.join('app', 'data', 'CAP_author_pubs_sample.csv')
		CSV.foreach(filename, :headers => true) do |row|

			make call here to get the SW record based on pmid

			contribution = row.parse_csv
			profile_id = contribution[1]
			publication_id = contribution[0]
			status = contribution[4]
			highlight = contribution[5]

			#setup a person record for the profile id (maybe getting full profile info from somewhere?)

  			Person.create!  (or just check that the id already exists.
  			PersonIdentifier  (add the cap profile id) 			

			#get the pubmed id then get the sciencewire record, then create pub, then associate the two:
  			
  			Source_Record.create
  			Publication.create!
			Publication_Source_Record.create

			# then associate the pub with the person, i.e., create the contribution

			Contribution.create!
  			
		end
	end
end
=end
# 1. import profiles - create a Person record with values from profile record.
# 2. import contributions (person/pubmed pairs)
# 3. import hand-entered Publication_Source_Record
=begin
#OLD should soon be deleted
	def pull_records_from_pubmed(pmid_list)

			pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}"}.join
	     	# puts pmidValuesForPost
			http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")
			
			request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
			request.body = pmidValuesForPost
			response = http.request(request)
			xml_doc = Nokogiri::XML(response.body)
			#http.finish
   			xml_doc
	end

#OLD shold soon be deleted
def get_and_store_records_from_pubmed_OLD(pmids)
		pmidValuesForPost = pmids.collect { |pmid| "&id=#{pmid}"}.join
		http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")	
		request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
		request.body = pmidValuesForPost
		http.start
		the_incoming_xml = http.request(request).body
		http.finish
		count = 0
		source_records = []
		
		Nokogiri::XML(the_incoming_xml).xpath('//PubmedArticle').each do |pub_doc|
	  		pmid = pub_doc.xpath('MedlineCitation/PMID').text
	  		
	  		#source_fingerprint = Digest::SHA2.hexdigest(pub_doc)     
	        begin        
	          	count += 1
	          	pmids.delete(pmid)
	          	source_records << PubmedSourceRecord.new(
                      :pmid => pmid,
	                  :source_data => pub_doc.to_xml,
	                  :is_active => true)
	          #        :source_fingerprint => source_fingerprint)
		    rescue Exception => e  
	          puts e.message  
	          puts e.backtrace.inspect  
	          puts "the offending pmid: " + pmid.to_s
	        end
	        
	    end
    	puts source_records.length.to_s + " records about to be created."
    	PubmedSourceRecord.import source_records 
    	puts count.to_s + " pmids were processed. "
    	puts pmids.length.to_s + " pmids weren't processed: " 			
	end

#OLD should soon be deleted
def get_mesh_and_abstract_from_pubmed(pmid_list)
	    mesh_values_and_abstracts_for_all_records = Hash.new
	    pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}"}.join
	    #start_time = Time.now
	    http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")
	    request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
	    request.body = pmidValuesForPost
	    #puts "PubMed call took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
	    #start_time = Time.now
	    Nokogiri::XML(http.request(request).body).xpath('//PubmedArticle').each do |publication|
	      pmid = publication.xpath('//MedlineCitation/PMID').text
	      abstract = extract_abstract_from_pubmed_record(publication)
	      mesh_headings_for_record = extract_mesh_headings_from_pubmed_record(publication)
	      mesh_values_and_abstracts_for_all_records[pmid] = {mesh: mesh_headings_for_record, abstract: abstract}
	    end
	   # http.finish
	    #puts "extracting mesh from pubmed results took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
	    mesh_values_and_abstracts_for_all_records
	end
=end

