
namespace :cap do

	desc "poll cap for new authorship information"
    task :poll => :environment do
		CapAuthorsPoller.new.get_authorship_data
		#CapAuthorshipMailer.welcome_email("some test text").deliver
  	end

  	

end
