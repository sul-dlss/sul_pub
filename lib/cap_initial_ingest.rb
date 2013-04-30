require 'nokogiri'
require 'citeproc'
require 'sciencewire'

module CapInitialIngest

include Sciencewire

extend self
#ingest sciencewire records for cap pmid list and generate authors and contributions
def get_pubs_and_contributions_for_pmids_from_sciencewire(pmids, contribs)
    mesh_values_for_pmids = get_mesh_from_pubmed(pmids)
    sw_records_doc = pull_records_from_sciencewire_for_pmids(pmids)
    sw_records_doc.xpath('//PublicationItem').each do |sw_record_doc|
      pmid = sw_record_doc.xpath("PMID").text
      #ActiveRecord::Base.transaction do
        begin
          contribution = contribs[pmid]
          cap_profile_id = (contribution['faculty_id'])
          author = Author.where(cap_profile_id: cap_profile_id).first_or_create()
          create_or_update_pub_from_sw_doc(sw_record_doc, contribution['status'], mesh_values_for_pmids, author)
        rescue Exception => e  
          puts e.message  
          puts e.backtrace.inspect  
          puts "the offending pmid: " + pmid.to_s
          puts "the contrib: " + contribution.to_s
          puts "the author: " + author.to_s
        end
     # end
    end
  end




end