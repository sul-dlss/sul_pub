require 'csv'
require 'dotiw'
require 'activerecord-import'

namespace :cap_cutover do

desc "get all sciencewire source records for full cap dump"
task :pull_sw_for_cap, [:file_location] => :environment do |t, args|
  include ActionView::Helpers::DateHelper
  start_time = Time.now
  total_running_count = 0
  pmids_for_this_batch = Set.new
   lines = CSV.foreach(args.file_location, :headers => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        pmid = row[:pubmed_id].to_s()
        pmids_for_this_batch << pmid #unless SciencewireSourceRecords.exists?(pmid: pmid)
        if pmids_for_this_batch.length%1000 == 0 
          SciencewireSourceRecord.get_and_store_sw_source_records(pmids_for_this_batch)
          pmids_for_this_batch.clear
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)  
        end 
        if total_running_count%5000 == 0  then GC.start end
      end
      SciencewireSourceRecord.get_and_store_sw_source_records(pmids_for_this_batch)
      puts (total_running_count).to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time)
      puts lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."    
end


desc "get all pubmed source records for full cap dump"
task :pull_pubmed_for_cap, [:file_location] => :environment do |t, args|
  include ActionView::Helpers::DateHelper
  start_time = Time.now
  total_running_count = 0
  pmids_for_this_batch = Set.new
  cap_import_pmid_logger = Logger.new(Rails.root.join('log', 'cap_import_pmid.log'))
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


desc "create publication, author, contribution, publication_identifier, and population_membership records from full cap dump"
  task :build_from_cap_data, [:file_location] => :environment do |t, args|
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0
    @cap_import_logger = Logger.new(Rails.root.join('log', 'cap_import_pubs.log'))
    CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        build_pub_from_cap_data(row)
        if total_running_count%5000 == 0  then GC.start end
        if total_running_count%500 == 0 
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
        end
    end
end


desc "ingest existing cap hand entered pubs"
  task :ingest_man_pubs, [:file_location] => :environment do |t, args|
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0
    CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
      total_running_count += 1
      if total_running_count%500 == 0 then puts total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time) end
      author = create_author_and_population_membership(row)
      pub_hash = convert_manual_publication_row_to_hash(row, author.id.to_s)
      original_source = row.to_s
      Publication.build_new_manual_publication(Settings.cap_provenance, pub_hash, original_source) 
    end
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
            official_first_name: row[:official_first_name], 
            official_last_name: row[:official_last_name], 
            official_middle_name: row[:official_middle_name],
            cap_first_name: row[:cap_first_name], 
            cap_last_name: row[:cap_last_name], 
            cap_middle_name: row[:cap_middle_name],
            preferred_first_name: row[:preferred_first_name], 
            preferred_last_name: row[:preferred_last_name], 
            preferred_middle_name: row[:preferred_middle_name]
            )
       
#author.population_memberships.where(population_name: Settings.cap_population_name, cap_profile_id: cap_profile_id).first_or_create()
        if total_running_count%5000 == 0  then GC.start end
        if total_running_count%5000 == 0 then puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time) end
    end
end

def create_author_and_population_membership(cap_pub_data_for_this_pub)
  author = Author.where(cap_profile_id: cap_pub_data_for_this_pub[:profile_id]).first_or_create(
        official_first_name: cap_pub_data_for_this_pub[:official_first_name], 
        official_last_name: cap_pub_data_for_this_pub[:official_last_name], 
        official_middle_name: cap_pub_data_for_this_pub[:official_middle_name], 
        sunetid: cap_pub_data_for_this_pub[:sunetid], 
        university_id: cap_pub_data_for_this_pub[:university_id],
        email: cap_pub_data_for_this_pub[:email_address]
      )
  #author.population_memberships.where(population_name: Settings.cap_population_name, cap_profile_id: cap_pub_data_for_this_pub[:profile_id]).first_or_create()
  author
end

def build_pub_from_cap_data(cap_pub_data_for_this_pub)
  begin
    pmid = cap_pub_data_for_this_pub[:pubmed_id].to_s        

   # author = create_author_and_population_membership(cap_pub_data_for_this_pub)  
   author = Author.where(cap_profile_id: cap_pub_data_for_this_pub[:profile_id]).first
    pub = Publication.where(pmid: pmid).first 
    if pub.nil? 
      sciencewire_source_record = SciencewireSourceRecord.where(pmid: pmid).first
      unless sciencewire_source_record.nil?
        sw_pub_hash = sciencewire_source_record.get_source_as_hash
        unless sw_pub_hash.nil?
          pub = Publication.new(
            active: true,
            title: sw_pub_hash[:title],
            year: sw_pub_hash[:year],
            sciencewire_id: sw_pub_hash[:sw_id],
            pmid: pmid) 
          pub.build_from_sciencewire_hash(sw_pub_hash)
        end
      end
    end
    if pub.nil?
      pubmed_source_record = PubmedSourceRecord.where(pmid: pmid).first   
      unless pubmed_source_record.nil?
        pubmed_hash = pubmed_source_record.get_source_as_hash
        unless pubmed_hash.nil?
            pub = Publication.new(
                active: true,
                title: pubmed_hash[:title],
                year: pubmed_hash[:year],
                pmid: pmid)  
              pub.build_from_pubmed_hash(pubmed_hash)  
        end
      end
    end
   # pub = Publication.get_pub_by_pmid(pmid)
    unless pub.nil? || pub.contributions.exists?(:author_id => author.id)
      pub.contributions.where(:author_id => author.id).create(
          cap_profile_id: cap_pub_data_for_this_pub[:profile_id],
          status: cap_pub_data_for_this_pub[:authorship_status],
          visibility: cap_pub_data_for_this_pub[:visibility], 
          featured: cap_pub_data_for_this_pub[:featured])    
      pub.sync_publication_hash_and_db       
    end
    if pub.nil? 
      #puts "nil sw and pubmed record for pmid: " + pmid.to_s 
      
      @cap_import_logger.info "Invalid pmid: " + pmid.to_s 
      #File.open(Rails.root.join('log', 'get_pub_out.json')) "file.txt", "a+"){|f| f << pmid.to_s }
    end
  rescue Exception => e  
          puts e.message  
          puts e.backtrace.inspect  
          puts "the offending pmid: " + pmid.to_s
          puts "the contrib: " + cap_pub_data_for_this_pub.to_s
          puts "the author: " + author.to_s
  end  
end


def self.convert_manual_publication_row_to_hash(cap_pub_data_for_this_pub, author_id)
#puts cap_pub_data_for_this_pub.to_s

    record_as_hash = Hash.new
    
    record_as_hash[:provenance] = Settings.cap_provenance
    record_as_hash[:title] = cap_pub_data_for_this_pub[:article_title]
    record_as_hash[:abstract_restricted] = cap_pub_data_for_this_pub[:abstract] unless cap_pub_data_for_this_pub[:abstract].blank?
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
    journal_hash[:identifier] = [{:type => 'issn', :id => cap_pub_data_for_this_pub[:issn]}] unless cap_pub_data_for_this_pub[:issn].blank?
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
