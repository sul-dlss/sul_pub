namespace :sw do
  desc "harvest from sciencewire by email or known sciencewire pub ids"
  task :fortnightly_harvest => :environment do
    ScienceWireHarvester.new.harvest_pubs_for_all_authors
    #CapAuthorshipMailer.welcome_email("some test text").deliver
  end
  task :nightly_harvest => :environment do
  	puts "harvest triggered....."
  	#ScienceWireHarvester.new.do_nightly_harvest
  	#CapAuthorshipMailer.welcome_email("some test text").deliver
  end
end
