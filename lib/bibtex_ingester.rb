require 'bibtex'
require 'citeproc'
require 'dotiw'

class BibtexIngester
	@@book_type_mapping = ['book', 'booklet', 'inbook', 'incollection', 'manual', 'techreport']
	@@article_type_mapping = ['article', 'misc', 'unpublished']
	@@inproceedings_type_mapping = ['conference', 'proceedings', 'inproceedings']

    def ingest_from_source_directory    	
        Dir.open('/Users/jameschartrand/Documents/OSS/projects/stanford-cap/samples').each do | batch_dir_name |
        	 if File.directory? batch_dir_name
        	 	Dir.open(batch_dir_name).each do | bibtex_file_name |
        	 		BibTeX.open('/Users/jameschartrand/Documents/OSS/projects/stanford-cap/samples/batch1/345533.tex').each do | record |
        	 			ingest_record(batch_dir_name, bibtex_file_name, record)
        	 		end
        	 	end
        	 end  
        end
    end

    def ingest_record(batch_name, sunet_id, record)
    	begin
	    	author = Author.where(sunetid: sunet_id).first_or_create
	    	pub_hash = convert_bibtex_record_to_pub_hash(record, author)

	       	existing_source_record = BatchUploadedSourceRecord.where(sunet_id: sunet_id, title: record.title).first

	       	if existing_source_record 
	       		existing_source_record.update_attributes(
	       			batch_name: batch_name,
	       			sunet_id: sunet_id,
	       			successful_import: true
	        		bibtex_source_data: record.to_s,
	        		title: record.title,
	        		year: record.year)	
	       		pub = existing_source_record.publication
	       		pub.update_attributes(
	       			publication_type: record.type,
	       			title: record.title,
	       			pub_hash: pub_hash,
	        		year: record.year)
	       	else
	       		pub = Publication.create(
	       			active: true,
	       			publication_type: record.type,
	       			title: record.title,
	       			pub_hash: pub_hash,
	        		year: record.year)
	       		pub.batch_uploaded_source_record.create(
	       			is_active: true,
	       			batch_name: batch_name,
	       			sunet_id: sunet_id,
	       			successful_import: true,
	        		bibtex_source_data: record.to_s,
	        		title: record.title,
	        		year: record.year)	
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

		rescue => e

			error_message = 'some message'
		  	pub.batch_uploaded_source_record.create(
	       			is_active: true,
	       			batch_name: batch_name,
	       			sunet_id: sunet_id,
	       			successful_import: false,
	       			error_message: e.message
	        		bibtex_source_data: record.to_s,
	        		title: record.title,
	        		year: record.year)	
		end
    end

def convert_bibtex_record_to_pub_hash(record, author)

		sul_document_type = determine_sul_pub_type(record.type)

	    record_as_hash = Hash.new
	    
	    record_as_hash[:authorship] = [
        {            
          cap_profile_id: author.cap_profile_id,
          sul_author_id: author.id.to_s,
          status: 'approved',
          visibility: 'public',
          featured: false
        }
      ]

	    record_as_hash[:provenance] = Settings.batch_source
	    record_as_hash[:title] = record.title
	    record_as_hash[:booktitle] = record.booktitle
	    record_as_hash[:author] = record.author
	    record_as_hash[:editor] = record.editor
	    record_as_hash[:publisher] =  record.publisher
	    record_as_hash[:year] = record.year
	    record_as_hash[:month] = record.month
	    record_as_hash[:address] = record.address
	    record_as_hash[:howpublished] = record.howpublished

	    record_as_hash[:type] = sul_document_type
	    record_as_hash[:bibtex_type] = record.type

	    
	     if sul_document_type == Settings.sul_doc_types.inproceedings
	      conference_hash = {}
	      record_as_hash[:conference] = conference_hash unless conference_hash.empty?
	      
	    elsif sul_document_type == Settings.sul_doc_types.book
	      record_as_hash[:pages] = record.pages  
	    end

	    if sul_document_type == Settings.sul_doc_types.article || ! record.journal.blank?
	      journal_hash = {}   
	      journal_hash[:name] = record.journal
	      journal_hash[:volume] = record.volume
	      journal_hash[:issue] = record.issue
	      journal_hash[:articlenumber] = record.number
	      journal_hash[:pages] = record.pages
	       record_as_hash[:journal] = journal_hash
	    end
	    
	    unless record.series.blank?
	        book_series_hash = {}
	        book_series_hash[:title] = record.series 
	        book_series_hash[:volume] = record.volume
	        record_as_hash[:series] = book_series_hash 
	    end
	    
	 
	    record_as_hash
	  end

def determine_sul_pub_type(bibtex_type)
	if book_type_mapping.include?(bibtex_type) 
		Settings.sul_doc_types.book
	elsif article_type_mapping.include?(bibtex_type)
		Settings.sul_doc_types.article
	elsif inproceedings_type_mapping.include?(bibtex_type)
		Settings.sul_doc_types.inproceedings
	else
		nil
	end
end

# could use this directly on the bibtex record, but might be best to do this using the same routine as 
# all the other pubs.

  def add_citations_to_hash(pub_hash, bibtex_record)
  	pub_hash[:apa_citation] = CiteProc.process(cit_data_array, :style => apa_csl_file, :format => 'html')
    pub_hash[:mla_citation] = CiteProc.process(cit_data_array, :style => mla_csl_file, :format => 'html')
    pub_hash[:chicago_citation] 

  	citeproc_record = bibtex_record.to_citeproc
	pub_hash[:apa_citation] = CiteProc.process citeproc_record, :style => :apa
	pub_hash[:chicago_citation] = CiteProc.process citeproc_record, :style => 'chicago-author-date'
	pub_hash[:mla_citation] = CiteProc.process citeproc_record, :style => :mla
  end

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

