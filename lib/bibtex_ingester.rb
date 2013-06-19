require 'bibtex'
require 'citeproc'
require 'dotiw'

class BibtexIngester
	@@book_type_mapping = ['book', 'booklet', 'inbook', 'incollection', 'manual', 'techreport']
	@@article_type_mapping = ['article', 'misc', 'unpublished']
	@@inproceedings_type_mapping = ['conference', 'proceedings', 'inproceedings']
	
    def ingest_from_source_directory   
    	@batch_dir = '/Users/jameschartrand/Documents/OSS/projects/stanford-cap/bibtex_import_files'
    	@bibtex_import_logger = Logger.new(Rails.root.join('log', 'bibtext_import.log'))
	    @bibtex_import_logger.info "Started bibtext import #{DateTime.now}"  	
	    @total_records_processed = 0
        Dir.open(@batch_dir).each do | batch_dir_name |
        	next if batch_dir_name == '.' or batch_dir_name == '..' 
        	batch_dir_full_path = "#{@batch_dir}/#{batch_dir_name}"
        	if File.directory? batch_dir_full_path
        	 	Dir.open(batch_dir_full_path).each do | bibtex_file_name |
        	 		next if batch_dir_name == '.' or batch_dir_name == '..' 

        	 		file_full_path = "#{batch_dir_full_path}/#{bibtex_file_name}"
        	 		next if File.directory? file_full_path
        	 		@count_for_file = 0
        	 		@bibtex_file_logger = Logger.new(Rails.root.join('log', "#{file_full_path}_import.log"))
        	 		@bibtex_file_logger.info "Started bibtext import for file #{DateTime.now}"  
        	 		BibTeX.open(file_full_path).each do | record |
        	 		#	puts record.to_s
        	 			ingest_record(batch_dir_name, bibtex_file_name, record)
        	 			@count_for_file += 1
        	 			@total_records_processed += 1
        	 		end
        	 		@bibtex_file_logger.info "Ended bibtext import for file #{DateTime.now}" 
        	 		@bibtex_file_logger.info "#{@count_for_file} records processed."
        	 		puts "#{@count_for_file} records processed for file: #{bibtex_file_name}"
        	 		puts "#{@total_records_processed} records processed for"
        	 	end
        	 end  
        end
        @bibtex_import_logger.info "Finished bibtex import #{DateTime.now}"  
    end

    def ingest_record(batch_name, sunet_id, record)
    	#begin
	    	author = Author.where(sunetid: sunet_id).first_or_create
	    	pub_hash = convert_bibtex_record_to_pub_hash(record, author)
	    	title = record[:title].to_s

	       	existing_source_record = BatchUploadedSourceRecord.where(sunet_id: sunet_id, title: title).first

	       	source_attrib_hash = {
	       		is_active: true,
	       		sunet_id: sunet_id, 
	       		batch_name: batch_name,
	       		successful_import: true,
        		bibtex_source_data: record.to_s
        	}
        	unless record["title"].blank? then source_attrib_hash[:title] =  record.title.to_s end 
        	unless record["year"].blank? then source_attrib_hash[:year] =  record.year.to_s end 
	       	pub_attrib_hash = {
	       		active: true,
       			publication_type: record.type.to_s,
       			pub_hash: pub_hash
       		}
        	unless record["title"].blank? then pub_attrib_hash[:title] =  record.title.to_s end 
        	unless record["year"].blank? then pub_attrib_hash[:year] =  record.year.to_s end 
	       	if existing_source_record 
	       		existing_source_record.update_attributes(source_attrib_hash)	
	       		pub = existing_source_record.publication
	       		pub.update_attributes(pub_attrib_hash)
	       	else
	       		pub = Publication.create(pub_attrib_hash)
	       		BatchUploadedSourceRecord.create(publication_id: pub.id).update_attributes(source_attrib_hash)
	       		#pub.batch_uploaded_source_record.create(source_attrib_hash)	
	       	end

	     	Contribution.where(
		     		author_id: author.id, 
		     		publication_id: pub.id).
	     		first_or_create(
	     			status: "approved",
	     			visibility: "public",
	     			featured: false)
	     	
	     	
			#pub.set_last_updated_value_in_hash
		    #pub.set_sul_pub_id_in_hash
		    #pub.publication_identifiers.create(
		    #	certainty: 'certain', 
		   # 	identifier_type: 'SULPubId' 
		   # 	identifier_value: pub.id.to_s, 
		    #	identifier_uri: 'http://sulcap.stanford.edu/publications/' + pub.id.to_s
		    #	)

		  	#pub.save
		  	pub.sync_publication_hash_and_db

		#rescue => e
		#	@bibtex_import_logger.error "Error with file #{sunet_id}" 
		#	@bibtex_import_logger.error "See the log file for #{sunet_id} for details." 
		#	@bibtex_file_logger.error "Error: #{DateTime.now}"
		#	@bibtex_file_logger.error e.message
		#	@bibtex_import_logger.error e.backtrace	  
		#	puts e.message
		#	puts e.backtrace
			# still store the source record, but indicate an error occured.
			# or reset the existing 
=begin			pub.batch_uploaded_source_record.where(
					batch_name: batch_name,
	       			sunet_id: sunet_id,
	       			title: record.title,
	        		year: record.year).first_or_create(
		       			is_active: true,
		       			successful_import: false,
		       			error_message: e.message,
		        		bibtex_source_data: record.to_s
	        		)	
=end	
		#end
    end

def convert_bibtex_record_to_pub_hash(record, author)

	sul_document_type = determine_sul_pub_type(record.type.to_s)

    record_as_hash = Hash.new
    
    authorship_hash = {
      sul_author_id: author.id,
      status: 'approved',
      visibility: 'public',
      featured: false}
    unless author.cap_profile_id.blank?  then authorship_hash[:cap_profile_id] = author.cap_profile_id end
    
    record_as_hash[:authorship] = [ authorship_hash ]
      

    record_as_hash[:provenance] = Settings.batch_source
    unless record["title"].blank? then record_as_hash[:title] = record.title.to_s end
    unless record["booktitle"].blank? then record_as_hash[:booktitle] = record.booktitle.to_s end
    unless record["author"].blank? 
     record_as_hash[:author] = record.author.collect { |author| {:name => author.to_s} } 
 	end
    		
    unless record["editor"].blank? then record_as_hash[:editor] = record.editor.to_s end
    unless record["publisher"].blank? then record_as_hash[:publisher] =  record.publisher.to_s end
    unless record["year"].blank? then record_as_hash[:year] = record.year.to_s end
    unless record["address"].blank? then record_as_hash[:address] = record.address.to_s end
    unless record["howpublished"].blank? then record_as_hash[:howpublished] = record.howpublished.to_s end

    record_as_hash[:type] = sul_document_type
    record_as_hash[:bibtex_type] = record.type.to_s

     if sul_document_type == Settings.sul_doc_types.inproceedings
      unless record["organization"].blank? then conference_hash = {organization: record_as_hash[:organization]} end
      unless conference_hash.nil? then record_as_hash[:conference] = conference_hash end
    end

    if sul_document_type == Settings.sul_doc_types.article || ! record.journal.blank?
      journal_hash = {}   
      unless record["journal"].blank? then journal_hash[:name] = record.journal.to_s end
      unless record["volume"].blank? then journal_hash[:volume] = record.volume.to_s end
      unless record["issue"].blank? then journal_hash[:issue] = record.issue.to_s end
      unless record["number"].blank? then journal_hash[:articlenumber] = record.number.to_s end
      unless record["pages"].blank? then journal_hash[:pages] = record.pages.to_s end
      unless journal_hash.empty? then record_as_hash[:journal] = journal_hash end
    elsif 
    	 # if this is an article then the pages go in the article object, but if not put it in the main object.
      unless record["pages"].blank? then record_as_hash[:pages] = record.pages.to_s  end
    end
    
    unless ! record["series"] 
        book_series_hash = {}
        unless record["series"].blank? then book_series_hash[:title] = record.series.to_s  end
        unless record["volume"].blank? then book_series_hash[:volume] = record.volume.to_s end
        unless book_series_hash.empty then record_as_hash[:series] = book_series_hash  end
    end
    
    record_as_hash

end

def determine_sul_pub_type(bibtex_type)
	if @@book_type_mapping.include?(bibtex_type) 
		Settings.sul_doc_types.book
	elsif @@article_type_mapping.include?(bibtex_type)
		Settings.sul_doc_types.article
	elsif @@inproceedings_type_mapping.include?(bibtex_type)
		Settings.sul_doc_types.inproceedings
	else
		nil
	end
end

# could use the following code directly on the bibtex record, but might be best to do this using the same routine as 
# all the other pubs.

  #def add_citations_to_hash(pub_hash, bibtex_record)
 # 	pub_hash[:apa_citation] = CiteProc.process(cit_data_array, :style => apa_csl_file, :format => 'html')
  #  pub_hash[:mla_citation] = CiteProc.process(cit_data_array, :style => mla_csl_file, :format => 'html')
  #  pub_hash[:chicago_citation] 

  #	citeproc_record = bibtex_record.to_citeproc
 #	pub_hash[:apa_citation] = CiteProc.process citeproc_record, :style => :apa
#	pub_hash[:chicago_citation] = CiteProc.process citeproc_record, :style => 'chicago-author-date'
#	pub_hash[:mla_citation] = CiteProc.process citeproc_record, :style => :mla
 # end

=begin
book = ['book', 'inbook', 'incollection', 'manual', 'techreport']
article = ['article', 'misc', 'unpublished']
inproceedings = ['conference', 'proceedings', 'inproceedings']


		
		booklet
		inbook
		incollection
		manual
		techreport
		
article:
		article
		misc
		unpublished
		
inproceedings:
		conference
		proceedings
		inproceedings
		
discard:  
		mastersthesis
		phdthesis

we'll keep original bibtex type, putting it in 'bibtex_type' field.
=end

end

