
namespace :sul do

desc "rebuild authorship for selected pubs"
  task :update_contribs_in_hash => :environment do
        
    #  publications = Publication.arel_table
	#	Publication.where(publications[:pub_hash].
    #    	matches("%okogiri%")).
    #    	each {|publication| publication.rebuild_pub_hash }
  	Publication.find_each {|pub| pub.rebuild_authorship }
  end

  desc "rebuild authorship for selected pubs"
  task :rebuild_bad_hashes => :environment do
        
      publications = Publication.arel_table
		Publication.where(publications[:pub_hash].
        	matches("%okogiri%")).
        	each {|publication| publication.rebuild_pub_hash }
  	#Publication.find_each {|pub| pub.rebuild_authorship }
  end

end 