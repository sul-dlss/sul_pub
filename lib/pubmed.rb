require 'nokogiri'

module Pubmed
	
	#"PUBLICATION_ID","FACULTY_ID","LAST_MODIFIED_DATE","LAST_MODIFIED_USER_ID","STATUS","HIGHLIGHT_IND"
	#20069,4132,26-SEP-04 02.58.58.000000000 PM,21,"new",0
	
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
	      pmid = publication.xpath('MedlineCitation/PMID').text
	      abstract = publication.xpath('MedlineCitation/Article/Abstract/AbstractText').text
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
	      mesh_values_and_abstracts_for_all_records[pmid] = {mesh: mesh_headings_for_record, abstract: abstract}
	    end
	    #puts "extracting mesh from pubmed results took: " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
	    mesh_values_and_abstracts_for_all_records
	end

	def pull_records_from_pubmed(pmid_list)

			pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}"}.join
	     	# puts pmidValuesForPost
			http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")
			
			request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
			request.body = pmidValuesForPost
			response = http.request(request)
			xml_doc = Nokogiri::XML(response.body)
		#	puts xml_doc.to_xml
			
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

