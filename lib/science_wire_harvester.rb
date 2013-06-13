require 'dotiw'
class ScienceWireHarvester
include ActionView::Helpers::DateHelper
#harverst sciencewire records for all authors using author information
	def harvest_pubs_from_sciencewire_for_all_authors
		
	    #Author.find_each(:batch_size => 100) do |author|
	    # random = rand(Author.count - 50)
	    #  author = Author.new(:pubmed_last_name => "levin", pubmed_first_initial: "c", pubmed_middle_initial: "s", sunetid: "cslevin")
	     #author = Author.new(:pubmed_last_name => "lee", pubmed_first_initial: "j", pubmed_middle_initial: "t", sunetid: "jtlee")
	    start_time = Time.now
	    # some counts for reporting
	    @total_suggested_count = 0
	    @new_pubs_created_count = 0

	    @author_count = 0
	    @contributions_created_count = 0
	    @existing_contributions_count = 0

	    @total_new_pubmed_source_count = 0
	    @total_new_sciencewire_source_count = 0
	    
	    @suggestions_with_pubmed_ids_count = 0

	    @matches_on_existing_swid_count = 0
	    @matches_on_existing_pmid_count = 0
	    @matches_on_issn_count = 0;
	    @matches_on_title_count = 0;

	    # our two queues for sciencewire and pubmed calls
	    @records_queued_for_sciencewire_retrieval = {}
	    @records_queued_for_pubmed_retrieval = {}

		@pmid_logger = Logger.new(Rails.root.join('log', 'pmid.log'))
	    @sw_harvest_logger = Logger.new(Rails.root.join('log', 'sw_test_harvest.log'))
	    @sw_harvest_logger.info "Started authorship harvest " + DateTime.now.to_s
	    @sciencewire_client = ScienceWireClient.new
	    @pubmed_client = PubmedClient.new
	    #IO.foreach(Rails.root.join('app', 'data', '2013_06_06_univIds_from_don_for_harvest_qa.txt')) do |line|
	    #Author.where(active_in_cap: true).limit(100).offset(19086).find_each(:batch_size => 500) do |author|
	  #  Author.where(active_in_cap: true, import_enabled: true).limit(5).offset(3000).each do |author|
	  Author.where(active_in_cap: true, import_enabled: true).limit(10).offset(4000).each do |author|
	    	#author = Author.where(university_id: line).first
	    	#if author 
	    	begin
	    		@harvested_for_author_count = 0
		    	@author_count += 1
		        last_name = author.official_last_name
		        first_name = author.official_first_name
		        middle_name = author.official_middle_name
		        profile_id = author.cap_profile_id
		        email = author.email

		       # seed_list = author.approved_sw_ids.collect { | sw_id | sw_id.identifier_value }
		       seed_list = get_seed_list_for_author(author)

		        puts "author: #{author.id} has seed list: #{seed_list}"
		        if @author_count%50 == 0
		        	string_to_print = "Harvested #{@total_suggested_count.to_s} suggestions so far for #{@author_count.to_s} authors - " + DateTime.now.to_s
		        	@sw_harvest_logger.info string_to_print
		        	puts string_to_print
		        end
		        unless email.blank? then email_list = [email] end
		        suggested_sciencewire_ids = @sciencewire_client.get_sciencewire_id_suggestions(last_name, first_name, middle_name, email_list, seed_list)
		        suggested_sciencewire_ids.each do |suggested_sciencewire_id|
		        	@total_suggested_count += 1
		        	was_record_created = create_contrib_for_pub_if_exists(suggested_sciencewire_id, author)
		        	if ! was_record_created		
		        		# queue up sciencewire id, along with any associated authors, for batched retrieval and processing
		        		@records_queued_for_sciencewire_retrieval[suggested_sciencewire_id] ||= []
		        		@records_queued_for_sciencewire_retrieval[suggested_sciencewire_id] << author.id 

		        		#puts @records_queued_for_sciencewire_retrieval.to_s
		        	end
		        end   
		    rescue => e
		      @sw_harvest_logger.info "Error for #{author.official_last_name} - #{author.cap_profile_id} "
		      @sw_harvest_logger.info e.message
		      puts e.backtrace.inspect
		    end
		    #@sw_harvest_logger.info "#{author.official_last_name} - #{author.cap_profile_id} has #@harvested_for_author_count new harvested records."
	      
	     	if @records_queued_for_sciencewire_retrieval.length > 100
	        	process_queued_sciencewire_suggestions
	        end

	        if @records_queued_for_pubmed_retrieval.length > 4000
	        	process_queued_pubmed_records
	        end
		      		#else
	      	#	@sw_harvest_logger.info "no author found for university_id: " + line
	      
	    end 
	    # finish up any left in a batch of less than 3k or 4k
	    process_queued_sciencewire_suggestions
	    process_queued_pubmed_records
	    @sw_harvest_logger.info "Finished harvest at " + DateTime.now.to_s

    	@sw_harvest_logger.info "#{@total_suggested_count} total records were suggested for #{@author_count} authors." 
    	
    	@sw_harvest_logger.info "#{@existing_contributions_count.to_s} existing contributions were found." 
    	@sw_harvest_logger.info "#{@contributions_created_count.to_s} new contributions were created." 

    	@sw_harvest_logger.info "#{@total_new_pubmed_source_count.to_s} new pubmed source records were created." 
    	@sw_harvest_logger.info "#{@total_new_sciencewire_source_count.to_s} new sciencewire source records were created." 

    	@sw_harvest_logger.info "#{@new_pubs_created_count.to_s} new publications were created." 

    	@sw_harvest_logger.info "#{@matches_on_existing_swid_count.to_s} existing publications were found by sciencewire id." 
    	@sw_harvest_logger.info "#{@matches_on_existing_pmid_count.to_s} existing publications were deduped by pmid." 
    	@sw_harvest_logger.info "#{@matches_on_issn_count.to_s} existing publications were deduped by issn." 
    	@sw_harvest_logger.info "#{@matches_on_title_count.to_s} existing publications were deduped by title." 
	end

	def get_seed_list_for_author(author)
		Publication.joins(:contributions => :author).
              where("author_id = ? ", author.id).
              where(Publication.arel_table[:sciencewire_id].not_eq(nil)).
              pluck(:sciencewire_id)            
	end

	def create_contribs_for_author_ids_and_pub(author_ids, pub)
		author_ids.each do | author_id |
			add_contribution_for_harvest_suggestion(Author.find(author_id), pub)
		end
	end

	def create_contrib_for_pub_if_exists_by_author_ids(sciencewire_id, author_ids)
		existing_pub = Publication.where(sciencewire_id: sciencewire_id).first
    	if existing_pub
    		create_contribs_for_author_ids_and_pub(author_ids, existing_pub)
	    	matches_on_existing_swid_count += 1
	    	true
	    else
	    	false
    	end    	
	end

	def create_contrib_for_pub_if_exists(sciencewire_id, author)
		existing_pub = Publication.where(sciencewire_id: sciencewire_id).first
    	if existing_pub
    		add_contribution_for_harvest_suggestion(author, existing_pub)
    		@matches_on_existing_swid_count += 1
    		true
	    else
	    	false
    	end
	end

	def add_contribution_for_harvest_suggestion(author, publication)
				
		contrib = Contribution.where(
			publication_id: publication.id, 
			author_id: author.id).first
		if contrib 
			@existing_contributions_count += 1
		else
			Contribution.create(
			publication_id: publication.id, 
			author_id: author.id,
			cap_profile_id: author.cap_profile_id,
			status: 'new',
			visibility: 'private',
			featured: false )
			@contributions_created_count += 1
		end
		#puts "new contrib id: #{contrib.id} for author: #{author.id} and pub: #{publication.id}"
	end

	def process_queued_sciencewire_suggestions
		list_of_sw_ids = @records_queued_for_sciencewire_retrieval.keys.join(',')
		sw_records_doc = @sciencewire_client.get_full_sciencewire_pubs_for_sciencewire_ids(list_of_sw_ids)
		sw_records_doc.xpath('//PublicationItem').each do |sw_doc|
	        
	        sciencewire_id = sw_doc.xpath("PublicationItemID").text
	        pmid = sw_doc.xpath("PMID").text
	        source_record_was_created = SciencewireSourceRecord.save_sw_source_record(sciencewire_id, pmid, sw_doc.to_xml)
	        if source_record_was_created then @total_new_sciencewire_source_count += 1 end
	        create_or_update_pub_and_contribution_with_harvested_sw_doc(sw_doc, @records_queued_for_sciencewire_retrieval[sciencewire_id])
	        	#puts "record: " + sw_doc.xpath("Title").text
	        	#puts "sw id: " + sw_doc.xpath("PublicationItemID").text
	        	#puts "author: " + sw_doc.xpath('AuthorList').text
	         	# ActiveRecord::Base.transaction do
		        #  end # transaction end
		end 
		@records_queued_for_sciencewire_retrieval.clear
	end

	def create_or_update_pub_and_contribution_with_harvested_sw_doc(incoming_sw_xml_doc, author_ids)
		#puts "author ids: " + author_ids.to_s
	    pub_hash = SciencewireSourceRecord.convert_sw_publication_doc_to_hash(incoming_sw_xml_doc) 
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
	    active = true
	    #disambig rules:  1.check for existing pub by sw_id, pmid 2.Look for ISSN. If matches, need to also check for year and first page. 3.Look for Title, year, starting page

		# although we've already checked earlier, check again for an existing pub
		# with this scienciewire id in case one got created in the mean time
		was_record_created = create_contrib_for_pub_if_exists_by_author_ids(sciencewire_id, author_ids)
		if ! was_record_created	
	    	# nope, now check for an existing pub by pmid or issn/pages or title/year/pages
	    	if !pmid.blank? 
	    		pub = Publication.where(pmid: pmid).first unless pmid.blank?
	    		if pub
	    			@pmid_logger.info pmid.to_s
	    			@matches_on_existing_pmid_count  +=1
	    		else
	    			# we don't have an existing sul pub for this pmid so queue this up for batch processing,
	    			# storing the pmid, author.id, and sw_hash. 
	    			@records_queued_for_pubmed_retrieval[pmid] ||= {}
	    			@records_queued_for_pubmed_retrieval[pmid][:sw_hash] = pub_hash
	    			@records_queued_for_pubmed_retrieval[pmid][:authors] = author_ids
	    			#puts @records_queued_for_pubmed_retrieval.to_s
	    		end
	    	else 
				if !issn.blank? && !pages.blank?
    				pub = Publication.where(issn: issn, pages: pages, year: year).first
    				if pub then @matches_on_issn_count += 1 end
    			end
    			if pub.nil? 
    				pub = Publication.where(title: title, year: year, pages: pages).first
    				if pub then @matches_on_title_count += 1 end
    			end
    			# if still no pub then create a new pub 
				if pub.nil? 
					pub = create_new_harvested_pub(active, title, year, issn, pages, type, sciencewire_id, pmid)
	    		end
			end
			if pub 
				create_contribs_for_author_ids_and_pub(author_ids, pub)
			    pub.build_from_sciencewire_hash(pub_hash)
			    pub.sync_publication_hash_and_db
			end		
		end
	end


	def create_new_harvested_pub(active, title, year, issn, pages, type, sciencewire_id, pmid)
		@new_pubs_created_count += 1
		Publication.create(
          	active: true,
            title: title,
            year: year,
            issn: issn,
            pages: pages,
      		publication_type: type,
            sciencewire_id: sciencewire_id,
            pmid: pmid)  	
		
	end
	

	def process_queued_pubmed_records

		begin
			puts "in process queued pubmed records"
			pubmed_source_record = PubmedSourceRecord.new
			pub_med_records = @pubmed_client.fetch_records_for_pmid_list(@records_queued_for_pubmed_retrieval.keys)
			Nokogiri::XML(pub_med_records).xpath('//PubmedArticle').each do |pub_doc|
				puts "processing one of the pubmed xml articles."
		  		pmid = pub_doc.xpath('MedlineCitation/PMID').text    
		        pubmed_source_record = PubmedSourceRecord.create_pubmed_source_record(pmid, pub_doc)
		        if pubmed_source_record then @total_new_pubmed_source_count += 1 end
	          	pub_hash = @records_queued_for_pubmed_retrieval[pmid][:sw_hash]
				author_ids = @records_queued_for_pubmed_retrieval[pmid][:authors]
			    pub = create_new_harvested_pub(true, pub_hash[:title], pub_hash[:year], pub_hash[:issn], pub_hash[:pages], pub_hash[:type], pub_hash[:sw_id], pmid)
		        abstract = pubmed_source_record.extract_abstract_from_pubmed_record(pub_doc)
		        mesh = pubmed_source_record.extract_mesh_headings_from_pubmed_record(pub_doc)

		        unless mesh.blank? then pub_hash[:mesh_headings] = mesh end
		        unless abstract.blank? then pub_hash[:abstract] = abstract end
		        
		        create_contribs_for_author_ids_and_pub(author_ids, pub)
		        pub.pub_hash = pub_hash
		        pub.sync_publication_hash_and_db
	    	end

		rescue => e 
          puts e.message  
          puts e.backtrace.inspect  
         # puts "the offending pmid: " + pmid.to_s
      	end
      	@records_queued_for_pubmed_retrieval.clear

    end

	

end