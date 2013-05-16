
require 'cap_initial_ingest'
require 'smarter_csv'
require 'csv'
require 'sciencewire'
require 'pubmed'
require 'dotiw'
#require 'activerecord-import'

#books = []
#10.times do |i| 
#  books << Book.new(:name => "book #{i}")
#end
#Book.import books

namespace :cap do

  desc "poll cap for authorship information"
    task :poll => :environment do
  end

desc "get all sciencewire source records for full cap dump"
task :pull_sw_for_cap, [:file_location] => :environment do |t, args|
  include Sciencewire
  include ActionView::Helpers::DateHelper
  start_time = Time.now
  total_running_count = 0
  pmids_for_this_batch = Set.new
   lines = CSV.foreach(args.file_location, :headers => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        pmid = row[:pubmed_id].to_s()
        pmids_for_this_batch << pmid #unless SciencewireSourceRecords.exists?(pmid: pmid)
        
        if pmids_for_this_batch.length%1000 == 0 
         # puts pmids_for_this_batch.length.to_s + " distinct pmids submitted out of the batch of 1000."
          get_and_store_sw_source_records(pmids_for_this_batch)
          pmids_for_this_batch.clear
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
         
        end
        if total_running_count%5000 == 0  
        #  puts "Processed " + total_running_count.to_s + "lines of csv file."
          GC.start
        end
      end
      get_and_store_sw_source_records(pmids_for_this_batch)
      puts (total_running_count).to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time)
      puts lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."
         
  end

desc "get all pubmed source records for full cap dump"
task :pull_pubmed_for_cap, [:file_location] => :environment do |t, args|
  include Pubmed
  include ActionView::Helpers::DateHelper
  start_time = Time.now
  total_running_count = 0
  pmids_for_this_batch = Set.new
   lines = CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        pmid = row[:pubmed_id].to_s()
        
        pmids_for_this_batch << pmid
        
        if pmids_for_this_batch.length%4000 == 0

          get_and_store_records_from_pubmed(pmids_for_this_batch)
          pmids_for_this_batch.clear
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time)
          #break 
        end
        if total_running_count%4000 == 0  
        #  puts "Processed " + total_running_count.to_s + "lines of csv file."
          GC.start
        end      
      end
      # finish off the batch
      get_and_store_records_from_pubmed(pmids_for_this_batch)
      puts (total_running_count).to_s + "records were processed in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
      puts lines.to_s + " lines of file: " + args.file_location.to_s + " were processed."
  end

desc "create publication, author, contribution, publication_identifier, and population_membership records from full cap dump"
  task :build_from_cap_data, [:file_location] => :environment do |t, args|
    include CapInitialIngest
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0

    CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        build_pub_from_cap_data(row)
        if total_running_count%5000 == 0  
             # puts "Processed " + total_running_count.to_s + "lines of csv file."
              GC.start
            end
        if total_running_count%500 == 0 
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
        end
    end
  end

desc "ingest exising cap hand entered pubs"
  task :ingest_man_pubs, [:file_location] => :environment do |t, args|
    include CapInitialIngest
    include ActionView::Helpers::DateHelper
   
    start_time = Time.now
    total_running_count = 0
    CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
      total_running_count += 1
      if total_running_count%500 == 0 
        puts total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time)
      end
      create_authors_pubs_and_contributions_for_hand_entered_pubs(row)
    end
  end

desc "ingest all authors"
task :ingest_all_authors, [:file_location] => :environment do |t, args|
    include CapInitialIngest
    include ActionView::Helpers::DateHelper
    start_time = Time.now
    total_running_count = 0

    CSV.foreach(args.file_location, :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        cap_profile_id = row[:profile_id]
        author = Author.where(cap_profile_id: cap_profile_id).first_or_create(
        official_first_name: row[:official_first_name], 
        official_last_name: row[:official_last_name], 
        official_middle_name: row[:official_middle_name], 
        sunetid: row[:sunetid], 
        university_id: row[:university_id], 
        email: row[:email_address]
      )
      author.population_memberships.where(population_name: Settings.cap_population_name, cap_profile_id: cap_profile_id).first_or_create()
      if total_running_count%5000 == 0  
               # puts "Processed " + total_running_count.to_s + "lines of csv file."
                GC.start
      end
      if total_running_count%1000 == 0 
            puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time)
      end
    end
end

# DON'T USE THIS ANYMORE - WE NOW GET ALL PUBMED AND SCIENCEWIRE SOURCE RECORDS SEPARATELY.
  desc "ingest existing cap data - this does it all in one go.  gets sw, pubmed, and constructs local records"
  task :ingest_pubmed_pubs => :environment do
    include CapInitialIngest
    include ActionView::Helpers::DateHelper
    
    pmids_for_this_batch = []
    cap_pub_data_for_this_batch = {}  
    start_time = Time.now
    total_running_count = 0
    chunk_size = 500

    pmids_for_this_batch = []
    cap_pub_data_for_this_batch = {}
    CSV.foreach("/Users/jameschartrand/Downloads/cap_pubmed_publications_from_profiles_dev1_db_2013_05_10-1.csv", :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        pmid = row[:pubmed_id].to_s()
        pmids_for_this_batch << pmid
        cap_pub_data_for_this_batch[pmid] = row
        if total_running_count%500 == 0 
          
          create_authors_pubs_and_contributions_for_batch_from_sciencewire_and_pubmed(pmids_for_this_batch, cap_pub_data_for_this_batch)
          pmids_for_this_batch.clear
          cap_pub_data_for_this_batch.clear
          puts (total_running_count).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
        end
      
    end

    puts total_chunks.to_s + " total chuncks processed.  And, " + (total_running_count).to_s + " total files."

    #results = [] << {"pubmed_id"=>211, "faculty_id"=>10884, "status"=>"denied"}
    #results.each do |row|
   # end
  end



 


end
