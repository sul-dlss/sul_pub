require 'nokogiri'
require 'citeproc'
require 'bibtex'
require 'sul_pub'

namespace :cap do
  desc "ingest exising cap data"
  task :ingest_cap => :environment do
  	include SulPub
  	include ActionView::Helpers::DateHelper
	pmids = []
	contribs = Hash.new
  	Publication.delete_all
    Contribution.delete_all
    Author.delete_all
    PopulationMembership.delete_all

    client = Mysql2::Client.new(:host => "localhost", :username => "cap", :password => "cap", :database => "cap")
    results = client.query("select cap_old_publication.pubmed_id, 
      cap_old_faculty_publication.faculty_id, 
      cap_old_faculty_publication.status, 
      cap_old_faculty_publication.highlight_ind 
      from cap_old_faculty_publication join cap_old_publication 
      on cap_old_faculty_publication.publication_id = cap_old_publication.publication_id  
      where pubmed_id != 0 limit 800")
    		start_time = Time.now
        total_running_count = 0;
  
    		results.each do |row|
    			pmid = row['pubmed_id']
    			pmids << pmid
    			contribs[pmid.to_s] = row
		
    			if pmids.count == 400
    				create_new_pubs_and_contributions_for_pmids(pmids, contribs)
    				pmids.clear
            puts (total_running_count += 400).to_s + " in " + distance_of_time_in_words_to_now(start_time, include_seconds = true)
    			end
  			end
	
    end
    end	


