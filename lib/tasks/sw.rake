namespace :sw do
  desc "harvest from sciencewire by email or known sciencewire pub ids"
  task :fortnightly_harvest, [:starting_author_id, :name_only_query, :use_middle_name] => :environment do |t, args|
    args.with_defaults(:starting_author_id => 1, :name_only_query => false, :use_middle_name => true)
    starting_author_id = (args[:starting_author_id]).to_i
    harvester = ScienceWireHarvester.new
    Signal.trap("USR1") do
      harvester.debug = true
    end
    if(args[:name_only_query] =~ /^true$/i || args[:name_only_query] == true)
      harvester.name_only_query = true
    end
    if(args[:use_middle_name] =~ /^false$/ || args[:use_middle_name] == false)
      harvester.use_middle_name = false
    end
    harvester.harvest_pubs_for_all_authors(starting_author_id)
    #CapAuthorshipMailer.welcome_email("harvest complete").deliver
  end

  desc "Harvest high priority faculty using the name-only query"
  task :faculty_harvest, [:path_to_ids] => :environment do |t, args|
    harvester = ScienceWireHarvester.new
    Signal.trap("USR1") do
      harvester.debug = true
    end
    harvester.name_only_query = true
    harvester.use_middle_names = false
    ids = IO.readlines(args[:path_to_ids]).map {|l| l.strip}
    harvester.harvest_pubs_for_author_ids ids
  end
end
