
require 'cap_initial_ingest'
require 'smarter_csv'
require 'csv'
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

  desc "ingest exising cap data"
  task :ingest_pubmed_pubs => :environment do
    include CapInitialIngest
    include ActionView::Helpers::DateHelper
    #db_config = Rails.application.config.database_configuration[Rails.env]
    pmids_for_this_batch = []
    cap_pub_data_for_this_batch = {}
   # client = Mysql2::Client.new(:host => "localhost", :username => "cap", :password => "cap", :database => "cap", :encoding => "utf8")
    #results = client.query("select cap_old_publication.pubmed_id,
    #  cap_old_faculty_publication.faculty_id, 
    #  cap_old_faculty_publication.status
    #  from cap_old_faculty_publication join cap_old_publication 
    #  on cap_old_faculty_publication.publication_id = cap_old_publication.publication_id  
    #  where pubmed_id != 0 order by pubmed_id limit 200")

    # to run in batches of 5000:  limit 0,5000  then:  limit 5000,5000 then limit 10000,5000 then 15000,5000 etc.
    start_time = Time.now
    total_running_count = 0
    chunk_size = 500

    pmids_for_this_batch = []
    cap_pub_data_for_this_batch = {}
            # , :key_mapping => key
          #  cap_pubmed_publications_from_profiles_dev1_db_2013_05_10
          #cap_pubmed_test_simple
          #cap_pubmed_test.csv
          #cap_pubmed_publications_from_profiles_dev1_db_2013_05_10-1
   # total_chunks = SmarterCSV.process('/Users/jameschartrand/Downloads/cap_pubmed_publications_from_profiles_dev1_db_2013_05_10-1.csv', {:chunk_size => chunk_size, :quote_char => '"', :strip_chars_from_headers => '"'}) do |chunk|
      
      CSV.foreach("/Users/jameschartrand/Downloads/cap_pubmed_publications_from_profiles_dev1_db_2013_05_10-1.csv", :headers  => true, :header_converters => :symbol) do |row|
        total_running_count += 1
        pmid = row[:pubmed_id].to_s()
   #    puts "the pmid should be here:  "  + pmid
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



 desc "ingest exising cap hand entered pubs"
  task :ingest_man_pubs => :environment do
    include CapInitialIngest
    include ActionView::Helpers::DateHelper
   
    start_time = Time.now
    total_running_count = 0
#cap_manual_publications_from_profiles_dev1_db_2013_05_10-1
#/Users/jameschartrand/Downloads/cap_pubmed_test
    CSV.foreach("/Users/jameschartrand/Downloads/cap_manual_publications_from_profiles_dev1_db_2013_05_10-1.csv", :headers  => true, :header_converters => :symbol) do |row|
      total_running_count += 1
      if total_running_count%500 == 0 
        puts total_running_count.to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
      end
      create_authors_pubs_and_contributions_for_hand_entered_pubs(row)
    end

=begin
    chunk_size = 500
    total_chunks = SmarterCSV.process('/Users/jameschartrand/Downloads/cap_pubmed_test_simple.csv', {:chunk_size => chunk_size, :quote_char => '"', :strip_chars_from_headers => '"'}) do |chunk|  
      chunk.each do |row|   
        create_authors_pubs_and_contributions_for_hand_entered_pubs(row)  
      end
      puts (total_running_count += chunk_size).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
    end
    puts total_chunks.to_s + " total chuncks processed.  So, " + (total_chunks * chunk_size).to_s + " total files."
=end
  end

      key_mapping = {
      :"\"deprecated_publication_id\"" => :deprecated_publication_id,
:"\"pubmed_id\"" => :pubmed_id,
:"\"manually_entered\"" => :manually_entered,
:"\"profile_id\"" => :profile_id,
:"\"cap_first_name\"" => :cap_first_name,
:"\"cap_middle_name\"" => :cap_middle_name,
:"\"cap_last_name\"" => :cap_last_name,
:"\"preferred_first_name\"" => :preferred_first_name,
:"\"preferred_middle_name\"" => :preferred_middle_name,
:"\"preferred_last_name\"" => :preferred_last_name,
:"\"official_first_name\"" => :official_first_name,
:"\"official_middle_name\"" => :official_middle_name,
:"\"official_last_name\"" => :official_last_name,
:"\"sunetid\"" => :sunetid,
:"\"university_id\"" => :university_id,
:"\"authorship_status\"" => :authorship_status,
:"\"visibility\"" => :visibility,
:"\"featured\"" => :featured,
:"\"publication_title\"" => :publication_title,
:"\"article_title\"" => :article_title,
:"\"volume\"" => :volume,
:"\"issn\"" => :issn,
:"\"issue_no\"" => :issue_no,
:"\"publication_date\"" => :publication_date,
:"\"page_ref\"" => :page_ref,
:"\"abstract\"" => :abstract,
:"\"lang\"" => :lang,
:"\"country\"" => :country,
:"\"authors\"" => :authors,
:"\"primary_author\"" => :primary_author,
:"\"affiliation\"" => :affiliation,
:"\"last_modified_date\"" => :last_modified_date,
:"\"cap_import_time\"" => :cap_import_time,
:"\"first_published_date\"" => :first_published_date

    }

end
