require 'nokogiri'
require 'citeproc'
require 'sciencewire'

module CapInitialIngest

include Sciencewire
include Pubmed

extend self

def create_authors_pubs_and_contributions_for_hand_entered_pubs(cap_pub_data_for_this_pub)

      author = Author.where(cap_profile_id: cap_pub_data_for_this_pub[:profile_id]).first_or_create(
        official_first_name: cap_pub_data_for_this_pub[:official_first_name], 
        official_last_name: cap_pub_data_for_this_pub[:official_last_name], 
        official_middle_name: cap_pub_data_for_this_pub[:official_middle_name], 
        sunetid: cap_pub_data_for_this_pub[:sunetid], 
        university_id: cap_pub_data_for_this_pub[:university_id]
      #  email: cap_pub_data_for_this_pub[:email]
      )
      author.population_memberships.where(population_name: Settings.cap_population_name, cap_profile_id: cap_pub_data_for_this_pub[:profile_id]).first_or_create()
      
      pub_hash = convert_manual_publication_row_to_hash(cap_pub_data_for_this_pub, author.id.to_s)
      provenance = Settings.cap_provenance

      Publication.build_new_manual_publication(provenance, pub_hash, cap_pub_data_for_this_pub.to_s)
                     
  end

#ingest sciencewire records for cap pmid list and generate authors and contributions
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

  def convert_manual_publication_row_to_hash(cap_pub_data_for_this_pub, author_id)
#puts cap_pub_data_for_this_pub.to_s
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
    record_as_hash = Hash.new
    
    record_as_hash[:provenance] = Settings.cap_provenance
    record_as_hash[:title] = cap_pub_data_for_this_pub[:article_title]
    record_as_hash[:abstract] = cap_pub_data_for_this_pub[:abstract]
    unless cap_pub_data_for_this_pub[:authors].blank?
      record_as_hash[:author] = cap_pub_data_for_this_pub[:authors].split('|').collect{|author| {name: author}} 
    else 
      record_as_hash[:author] = []
    end
    primary_author = cap_pub_data_for_this_pub[:primary_author]
    unless primary_author.blank?
      primary_author = primary_author[1..-2]
      record_as_hash[:author] << {name: primary_author} 
    end
    
    record_as_hash[:year] = cap_pub_data_for_this_pub[:publication_date]
    
    record_as_hash[:type] = Settings.sul_doc_types.article
=begin   if !cap_pub_data_for_this_pub[:country].blank?
      puts "country: " + cap_pub_data_for_this_pub[:country].to_s
      puts "abstract: " + cap_pub_data_for_this_pub[:abstract].to_s
      puts "title: " + cap_pub_data_for_this_pub[:title].to_s
    end
=end
    record_as_hash[:country] = cap_pub_data_for_this_pub[:country] unless cap_pub_data_for_this_pub[:country].blank?
    
    
    record_as_hash[:identifier] = [{:type =>'old_cap_pub_id', :id => cap_pub_data_for_this_pub[:deprecated_publication_id]}]

    
    journal_hash = {}   
    journal_hash[:name] = cap_pub_data_for_this_pub[:publication_title]
    journal_hash[:volume] = cap_pub_data_for_this_pub[:volume]
    journal_hash[:issue] = cap_pub_data_for_this_pub[:issue_no]
    journal_hash[:pages] = cap_pub_data_for_this_pub[:page_ref]
    journal_hash[:identifier] = [{:type => 'issn', :id => cap_pub_data_for_this_pub[:issn]}]
    record_as_hash[:journal] = journal_hash
   
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



end