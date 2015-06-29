require 'nokogiri'

class PubmedSourceRecord < ActiveRecord::Base
  #validates_uniqueness_of :pmid
  #validates_presence_of :source_data

	def get_source_as_hash
		convert_pubmed_publication_doc_to_hash(Nokogiri::XML(source_data).xpath('//PubmedArticle'))
	end

  	def self.get_pub_by_pmid(pmid)
  		pubmed_pub_hash = PubmedSourceRecord.get_pubmed_hash_for_pmid(pmid)
  		unless pubmed_pub_hash.nil?
            pub = Publication.new(
              active: true,
              pmid: pmid)
            pub.build_from_pubmed_hash(pubmed_pub_hash)
            pub.sync_publication_hash_and_db
            pub.save
        end
        pub
  	end

  	def self.get_pubmed_hash_for_pmid(pmid)
  		pubmed_source_record = get_pubmed_source_record_for_pmid(pmid)
  		unless pubmed_source_record.nil?
  			pubmed_source_record.get_source_as_hash
  		end
  	end

  	def self.get_pubmed_source_record_for_pmid(pmid)
  		PubmedSourceRecord.where(pmid: pmid).first || PubmedSourceRecord.get_pubmed_record_from_pubmed(pmid)
  	end

  	def self.get_pubmed_record_from_pubmed(pmid)
  		get_and_store_records_from_pubmed([pmid])
  		PubmedSourceRecord.where(pmid: pmid).first
  	end

	def self.create_pubmed_source_record(pmid, pub_doc)
		PubmedSourceRecord.where(pmid: pmid).first_or_create(
                      :pmid => pmid,
	                  :source_data => pub_doc.to_xml,
	                  :is_active => true,
	                  :source_fingerprint => Digest::SHA2.hexdigest(pub_doc))
	end

	def self.get_and_store_records_from_pubmed(pmids)
		pmidValuesForPost = pmids.collect { |pmid| "&id=#{pmid}"}.join
		http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")
		request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
		request.body = pmidValuesForPost
		#http.start
		the_incoming_xml = http.request(request).body
		#http.finish
		count = 0
		source_records = []
		@cap_import_pmid_logger = Logger.new(Rails.root.join('log', 'cap_import_pmid.log'))
		Nokogiri::XML(the_incoming_xml).xpath('//PubmedArticle').each do |pub_doc|
	  		pmid = pub_doc.xpath('MedlineCitation/PMID').text
	        begin
	          	count += 1
	          	source_records << PubmedSourceRecord.new(
                      :pmid => pmid,
	                  :source_data => pub_doc.to_xml,
	                  :is_active => true,
	                  :source_fingerprint => Digest::SHA2.hexdigest(pub_doc))
	          	pmids.delete(pmid)
		    rescue => e
	          puts e.message
	          puts e.backtrace.inspect
	          puts "the offending pmid: " + pmid.to_s
	        end

	    end
    	#Sputs source_records.length.to_s + " records about to be created."
    	PubmedSourceRecord.import source_records
    	#puts count.to_s + " pmids were processed. "
    	#puts pmids.length.to_s + " pmids weren't processed: "
    	@cap_import_pmid_logger.info "Invalid pmids: " + pmids.to_a.join(',')

	end

	def extract_abstract_from_pubmed_record(pubmed_record)
		pubmed_record.xpath('MedlineCitation/Article/Abstract/AbstractText').text
	end

	def extract_mesh_headings_from_pubmed_record(pubmed_record)
		mesh_headings_for_record = []
	      pubmed_record.xpath('MedlineCitation/MeshHeadingList/MeshHeading').each do |mesh_heading|
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
		issn = publication.xpath('MedlineCitation/Article/Journal/ISSN').text
		record_as_hash[:issn] = issn unless issn.blank?
		journal_identifiers << {:type => 'issn', :id => issn, :url => 'http://searchworks.stanford.edu/?search_field=advanced&number=' + issn} unless issn.blank?
		journal_hash[:identifier] = journal_identifiers
		record_as_hash[:journal] = journal_hash

    record_as_hash[:identifier] = [{:type =>'PMID', :id => pmid, :url => 'http://www.ncbi.nlm.nih.gov/pubmed/' + pmid } ]
    doi = publication.at_xpath('//ArticleId[@IdType="doi"]')
    record_as_hash[:identifier] << {:type => 'doi', :id => doi.text, :url => 'http://dx.doi.org/' + doi.text} if doi

    #puts "the record as hash"
    #puts record_as_hash.to_s
    record_as_hash
  end

end


