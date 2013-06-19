require 'csv'
require 'dotiw'
require 'activerecord-import'

namespace :cap_cutover do

# to reubuild:
# run pull_sw_for_cap, pull_pubmed_for_cap, ingest_authors, create_pubs_from_cap, build_pubs, ingest_man_pubs
# then run cap_authorship_

desc "get all pubmed source records for full cap dump"
task :pull_pubmed_for_cap, [:file_location] => :environment do |t, args|
  include ActionView::Helpers::DateHelper
  start_time = Time.now
  total_running_count = 0
  pmids_for_this_batch = Set.new
  cap_import_pmid_logger = Logger.new(Rails.root.join('log', 'cap_import_pubmed_source_records.log'))
  cap_import_pmid_logger.info "Started pumed import " + DateTime.now.to_s
   lines = CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        pmid = row[:pubmed_id].to_s()   
        pmids_for_this_batch << pmid       
        if pmids_for_this_batch.length%4000 == 0
          PubmedSourceRecord.get_and_store_records_from_pubmed(pmids_for_this_batch)
          pmids_for_this_batch.clear
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time)
          #break 
        end
        if total_running_count%4000 == 0  then GC.start end        
      end
      # finish off the batch
      PubmedSourceRecord.get_and_store_records_from_pubmed(pmids_for_this_batch)
      puts total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
      puts lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."
      cap_import_pmid_logger.info "Finished pubmed import." + DateTime.now.to_s
      cap_import_pmid_logger.info lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."
      cap_import_pmid_logger.info total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
end

desc "get all sciencewire source records for full cap dump"
task :pull_sw_for_cap, [:file_location] => :environment do |t, args|
  include ActionView::Helpers::DateHelper
  start_time = Time.now
  total_running_count = 0
  pmids_for_this_batch = Set.new
  cap_import_sw_logger = Logger.new(Rails.root.join('log', 'cap_import_sciencewire_source_records.log'))
  cap_import_sw_logger.info "Started sciencewire import " + DateTime.now.to_s
   lines = CSV.foreach(args.file_location, :headers => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        pmid = row[:pubmed_id].to_s()
        pmids_for_this_batch << pmid #unless SciencewireSourceRecords.exists?(pmid: pmid)
        if pmids_for_this_batch.length%300 == 0 
          SciencewireSourceRecord.get_and_store_sw_source_records(pmids_for_this_batch)
          pmids_for_this_batch.clear
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)  
        end 
        if total_running_count%5000 == 0  then GC.start end
      end
      SciencewireSourceRecord.get_and_store_sw_source_records(pmids_for_this_batch)
      puts (total_running_count).to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time)
      puts lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."    
      cap_import_sw_logger.info "Finished sciencewire import." + DateTime.now.to_s
      cap_import_sw_logger.info lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."
      cap_import_sw_logger.info total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
end



#  ingest author files from csv.
desc "ingest authors "
task :ingest_authors, [:file_location] => :environment do |t, args|
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0

    CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        cap_profile_id = row[:profile_id]
       # author = Author.where(cap_profile_id: cap_profile_id).first_or_create
      #  if author.nil?
          Author.create(
            cap_profile_id: cap_profile_id,
            active_in_cap: row[:active_profile],
            sunetid: row[:sunetid],
            university_id: row[:university_id], 
            email: row[:email_address],
            emails_for_harvest: row[:email_address],
            official_first_name: row[:official_first_name], 
            official_last_name: row[:official_last_name], 
            official_middle_name: row[:official_middle_name],
            cap_first_name: row[:cap_first_name], 
            cap_last_name: row[:cap_last_name], 
            cap_middle_name: row[:cap_middle_name],
            preferred_first_name: row[:preferred_first_name], 
            preferred_last_name: row[:preferred_last_name], 
            preferred_middle_name: row[:preferred_middle_name],
            california_physician_license: (row[:ca_license_number])
            )
       
        if total_running_count%5000 == 0  then GC.start end
        if total_running_count%5000 == 0 then puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time) end
    end
end


desc "create publication and contribution records from full cap dump"
  task :create_pubs_from_cap, [:file_location] => :environment do |t, args|
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0
    @cap_import_logger = Logger.new(Rails.root.join('log', 'cap_create_pmid_pubs.log'))
    @cap_import_logger.info "Started cap build pub process " + DateTime.now.to_s
 
    lines = CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        
    author = Author.where(cap_profile_id: row[:profile_id]).first
    pub = Publication.where(pmid: row[:pubmed_id]).first_or_create
    pub.contributions.where(:author_id => author.id).first_or_create(
          cap_profile_id: row[:profile_id],
          status: row[:authorship_status],
          visibility: row[:visibility], 
          featured: row[:featured]) 

        if total_running_count%5000 == 0  then GC.start end
          
        if total_running_count%1000 == 0 
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
          @cap_import_logger.info total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
        end
    end
    @cap_import_logger.info "Finished import." + DateTime.now.to_s
    @cap_import_logger.info lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."
    @cap_import_logger.info total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)

end




desc "ingest existing cap hand entered pubs"
  task :ingest_man_pubs, [:file_location] => :environment do |t, args|
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0
    @cap_manual_import_logger = Logger.new(Rails.root.join('log', 'cap_import_man_pubs.log'))
    @cap_manual_import_logger.info "Started cap manual pub import process " + DateTime.now.to_s
    lines = CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
      total_running_count += 1
      if total_running_count%500 == 0 then puts total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time) end
      author = Author.where(cap_profile_id: row[:profile_id]).first
      pub_hash = convert_manual_publication_row_to_hash(row, author.id.to_s)
      original_source = row.to_s
      Publication.build_new_manual_publication(Settings.cap_provenance, pub_hash, original_source) 
    end
    @cap_manual_import_logger.info "Finished import." + DateTime.now.to_s
    @cap_manual_import_logger.info lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."
    @cap_manual_import_logger.info total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)

  end

desc "utility to rebuild pub hashes from sciencewire and pubmed sources for all pubs"
  task :build_pubs => :environment do
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0
    @cap_import_logger = Logger.new(Rails.root.join('log', 'cap_build_pubs.log'))
    @cap_import_logger.info "Started cap build pub process " + DateTime.now.to_s

   Publication.find_each do |pub|
        total_running_count += 1
        build_pub_from_sw_and_pubmed(pub)
        if total_running_count%5000 == 0  then GC.start end
          
        if total_running_count%1000 == 0 
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
          @cap_import_logger.info total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
        end
    end
    @cap_import_logger.info "Finished build." + DateTime.now.to_s
    @cap_import_logger.info total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)

end

desc "overwrite cap profile ids from CAP authorship feed - this is meant to be a very temporary, dangerous, and invasive procedure for creating qa machines for the School of Medicine testers."
    task :overwrite_profile_ids => :environment do
      CapProfileIdRewriter.new.rewrite_cap_profile_ids_from_feed
    end

desc "utility to rewrite the authorship in the pub hash from the db tables"
  task :rewrite_authorship => :environment do
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0
    @rebuild_authorship_logger = Logger.new(Rails.root.join('log', 'rebuild_authorship_in_hash.log'))
    @rebuild_authorship_logger.info "Started resync process " + DateTime.now.to_s

   Publication.find_each do |pub|
        total_running_count += 1
        pub.rebuild_authorship
        if total_running_count%5000 == 0  then GC.start end
          
        if total_running_count%1000 == 0 
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
          @rebuild_authorship_logger.info total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
        end
    end
    @rebuild_authorship_logger.info "Finished build." + DateTime.now.to_s
    @rebuild_authorship_logger.info total_running_count.to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)

end

desc "utility to extract data extract data from hash to publication object, modify as needed before running"
  task :update_pubs => :environment do
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0
    @cap_import_logger = Logger.new(Rails.root.join('log', 'cap_update_pubs.log'))
    @cap_import_logger.info "Started cap update pub process " + DateTime.now.to_s

   Publication.find_each do |pub|
        total_running_count += 1
        pub_hash = pub.pub_hash
        if pub_hash.respond_to?(:has_key?)
          if pub_hash.has_key?(:journal)
            issn = find_issn_id_identifiers(pub_hash[:journal][:identifier])  unless  pub_hash[:journal][:identifier].nil?
          elsif pub_hash.has_key?(:series)
            issn = find_issn_id_identifiers(pub_hash[:series][:identifier]) unless  pub_hash[:series][:identifier].nil?
          else
            issn = nil
          end
          pub.update_attributes(
            pages: pub_hash[:pages],
            issn: issn,
            publication_type: pub_hash[:type]
          )
        else
          @cap_import_logger.info pub.pmid
        end
        if total_running_count%5000 == 0  then GC.start end
          
        if total_running_count%1000 == 0 
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
          #@cap_import_logger.info total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
        end
    end
    @cap_import_logger.info "Finished update." + DateTime.now.to_s
    @cap_import_logger.info total_running_count.to_s + "records were updated in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)

end

def find_issn_id_identifiers(identifiers_array)
  issn = nil
    identifiers_array.each do |single_identifier_hash|
        if single_identifier_hash[:type] == 'issn'
          issn = single_identifier_hash[:id]
          break
        end
    end
    issn
end


#  update various author fields from csv.  
desc "update authors, utility to be used as needed for patches to records from csv file"
task :update_authors, [:file_location] => :environment do |t, args|
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0
    CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        cap_profile_id = row[:profile_id]
        author = Author.where(cap_profile_id: cap_profile_id).first.update_attributes(
         # active_in_cap: (row[:active_profile] == 'active'),
          california_physician_license: (row[:ca_license_number])
          )    
       # if total_running_count%5000 == 0  then GC.start end
        if total_running_count%5000 == 0 then puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time) end
    end
    puts total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time) 
end

def build_pub_from_sw_and_pubmed(pub)
  begin
    pmid = pub.pmid.to_s     

    sciencewire_source_record = SciencewireSourceRecord.where(pmid: pmid).first
    unless sciencewire_source_record.nil?
      sw_pub_hash = sciencewire_source_record.get_source_as_hash
      pub.update_attributes(
          active: true,
          title: sw_pub_hash[:title],
          year: sw_pub_hash[:year],
          sciencewire_id: sw_pub_hash[:sw_id],
          pub_hash: sw_pub_hash,
          pages: sw_pub_hash[:pages],
          issn: sw_pub_hash[:issn],
          publication_type: sw_pub_hash[:type])
      pub.add_any_pubmed_data_to_hash 
      
    else  
      pubmed_source_record = PubmedSourceRecord.where(pmid: pmid).first   
      pubmed_hash = pubmed_source_record.get_source_as_hash
      pub.update_attributes(
                active: true,
                title: pubmed_hash[:title],
                year: pubmed_hash[:year],
                pub_hash: pubmed_hash)    
    end
    pub.cutover_sync_hash_and_db       
    
  rescue Exception => e  
          @cap_import_logger.info e.message  
          @cap_import_logger.info e.backtrace.inspect  
          @cap_import_logger.info "the offending pmid: " + pmid.to_s
  end  
end



def self.convert_manual_publication_row_to_hash(cap_pub_data_for_this_pub, author_id)
#puts cap_pub_data_for_this_pub.to_s

    record_as_hash = Hash.new
    
    record_as_hash[:provenance] = Settings.cap_provenance
    record_as_hash[:title] = cap_pub_data_for_this_pub[:article_title]
   # record_as_hash[:abstract_restricted] = cap_pub_data_for_this_pub[:abstract] unless cap_pub_data_for_this_pub[:abstract].blank?
    unless cap_pub_data_for_this_pub[:authors].blank?
      record_as_hash[:author] = cap_pub_data_for_this_pub[:authors].split(',').collect{|author| {name: author}} 
    else 
      record_as_hash[:author] = []
    end
    primary_author = cap_pub_data_for_this_pub[:primary_author]
    unless primary_author.blank?
      primary_author = primary_author
      record_as_hash[:author] << {name: primary_author} 
    end
    
    record_as_hash[:year] = cap_pub_data_for_this_pub[:publication_date] unless cap_pub_data_for_this_pub[:publication_date].blank?
    
    record_as_hash[:type] = Settings.sul_doc_types.article

    record_as_hash[:country] = cap_pub_data_for_this_pub[:country] unless cap_pub_data_for_this_pub[:country].blank?
    
    record_as_hash[:identifier] = [{:type =>'legacy_cap_pub_id', :id => cap_pub_data_for_this_pub[:deprecated_publication_id]}]

    journal_hash = {}   
    journal_hash[:name] = cap_pub_data_for_this_pub[:publication_title] unless cap_pub_data_for_this_pub[:publication_title].blank?
    journal_hash[:volume] = cap_pub_data_for_this_pub[:volume] unless cap_pub_data_for_this_pub[:volume].blank?
    journal_hash[:issue] = cap_pub_data_for_this_pub[:issue_no] unless cap_pub_data_for_this_pub[:issue_no].blank?
    journal_hash[:pages] = cap_pub_data_for_this_pub[:page_ref] unless cap_pub_data_for_this_pub[:page_ref].blank?
    issn = cap_pub_data_for_this_pub[:issn]
    record_as_hash[:issn] = issn unless issn.blank?
    journal_hash[:identifier] = [{:type => 'issn', :id => issn}] unless issn.blank?
    record_as_hash[:journal] = journal_hash unless journal_hash.empty?
   
    record_as_hash[:authorship] = [
        {            
          cap_profile_id: cap_pub_data_for_this_pub[:profile_id],
          sul_author_id: author_id,
          status: cap_pub_data_for_this_pub[:authorship_status],
          visibility: cap_pub_data_for_this_pub[:visibility],
          featured: cap_pub_data_for_this_pub[:featured]
        }
      ]

    record_as_hash
  end
=begin
  key_mapping = {
      :DEPRECATED_PUBLICATION_ID => nil,
      :PUBMED_ID => nil,
      :MANUALLY_ENTERED => nil,
      :PROFILE_ID => nil,
      :CAP_FIRST_NAME => nil,
      :CAP_MIDDLE_NAME => nil,
      :CAP_LAST_NAME => nil,
      :PREFERRED_FIRST_NAME => nil,
      :PREFERRED_MIDDLE_NAME => nil,
      :PREFERRED_LAST_NAME => nil,
      :OFFICIAL_FIRST_NAME => nil,
      :OFFICIAL_MIDDLE_NAME => nil,
      :OFFICIAL_LAST_NAME => nil,
      :SUNETID => nil,
      :UNIVERSITY_ID => nil,
      
      :AUTHORSHIP_STATUS => nil,
      :VISIBILITY => nil,
      :FEATURED => nil,
      
      :PUBLICATION_TITLE => nil,
      :ARTICLE_TITLE => nil,
      :VOLUME => nil,
      :ISSN => nil,
      :ISSUE_NO => nil,
      :PUBLICATION_DATE => nil,
      :PAGE_REF => nil,
      :ABSTRACT => nil,   
      :COUNTRY => nil,
      
      :AUTHORS => nil,
      :PRIMARY_AUTHOR => nil,
      :LANG => nil,
      :AFFILIATION => nil,
      
      :LAST_MODIFIED_DATE => nil,
      :CAP_IMPORT_TIME => nil,
      :FIRST_PUBLISHED_DATE => nil
    }
=end   
 


end
