namespace :sw do
  desc "harvest from sciencewire by email or known sciencewire pub ids"
  task :fortnightly_harvest, [:starting_author_id] => :environment do |t, args|
     starting_author_id = (args[:starting_author_id] || 1).to_i
     harvester = ScienceWireHarvester.new
     Signal.trap("USR1") do
       harvester.debug = true
     end
     harvester.harvest_pubs_for_all_authors(starting_author_id)
    #CapAuthorshipMailer.welcome_email("harvest complete").deliver
  end
end
