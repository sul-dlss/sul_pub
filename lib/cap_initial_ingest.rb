require 'nokogiri'

module CapInitialIngest

extend self

# DON'T USE THIS ANYMORE - WE NOW INGEST ALL SW AND PUBMED RECORDS SEPARATELY.
#ingest sciencewire records for cap pmid list and generate authors and contributions
=begin
def create_authors_pubs_and_contributions_for_batch_from_sciencewire_and_pubmed(pmids, cap_pub_data_for_this_batch)
    pubmed_data_for_pmid_batch = get_mesh_and_abstract_from_pubmed(pmids)
    sw_records_doc = pull_records_from_sciencewire_for_pmids(pmids)
    #puts sw_records_doc.to_xml
    count = 0
    sw_records_doc.xpath('//PublicationItem').each do |sw_record_doc|
      pmid = sw_record_doc.xpath("PMID").text
      
      #ActiveRecord::Base.transaction do
        begin
          # we delete them as we get them so we can check what's left over.
          cap_pub_data_for_this_pub = cap_pub_data_for_this_batch.delete(pmid)
       #   puts cap_pub_data_for_this_pub.to_s
          cap_profile_id = cap_pub_data_for_this_pub[:profile_id]
          count += 1
          author = Author.where(cap_profile_id: cap_profile_id).first_or_create(
              official_first_name: cap_pub_data_for_this_pub[:official_first_name], 
              official_last_name: cap_pub_data_for_this_pub[:official_last_name], 
              official_middle_name: cap_pub_data_for_this_pub[:official_middle_name], 
              sunetid: cap_pub_data_for_this_pub[:sunetid], 
              university_id: cap_pub_data_for_this_pub[:university_id], 
              email: cap_pub_data_for_this_pub[:email]
            )
            author.population_memberships.where(population_name: Settings.cap_population_name, cap_profile_id: cap_profile_id).first_or_create()
            create_or_update_pub_from_sw_doc(sw_record_doc, cap_pub_data_for_this_pub[:authorship_status], cap_pub_data_for_this_pub[:visibility], cap_pub_data_for_this_pub[:featured], pubmed_data_for_pmid_batch, author)
            
        rescue Exception => e  
          puts e.message  
          puts e.backtrace.inspect  
          puts "the offending pmid: " + pmid.to_s
          puts "the contrib: " + cap_pub_data_for_this_pub.to_s
          puts "the author: " + author.to_s
        end
     # end
    end
    puts count.to_s + " pmids were processed. "
    puts cap_pub_data_for_this_batch.length.to_s + " pmids weren't processed: " 
    cap_pub_data_for_this_batch.each_key { |k| puts k.to_s}
  end
=end


end