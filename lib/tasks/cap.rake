
namespace :cap do

	desc "poll cap for new authorship information"
    task :poll => :environment do
		CapAuthorsPoller.new.get_authorship_data
		#CapAuthorshipMailer.welcome_email("some test text").deliver
  	end

  	desc "overwrite cap profile ids from CAP authorship feed - this is meant to be a very temporary, dangerous, and invasive procedure for creating qa machines for the School of Medicine testers."
    task :overwrite_profile_ids => :environment do
		CapProfileIdRewriter.new.rewrite_cap_profile_ids_from_feed
  	end

end
