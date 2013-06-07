require 'sul_solr'

namespace :sul do

desc "rebuild hashes for selected pubs"
  task :rebuild_pubs => :environment do
     
        
        publications = Publication.arel_table
		Publication.
        	where(publications[:pub_hash].
        	matches("%okogiri%")).
        	each {|publication| publication.rebuild_pub_hash }
  
  end
end 