namespace :sw do

  def harvester
    @harvester ||= begin
      h = ScienceWireHarvester.new

      Signal.trap("USR1") do
        harvester.debug = true
      end

      h
    end
  end

  # rake sw:fortnightly_harvest[1, 5]
  desc "harvest from sciencewire by email or known sciencewire pub ids"
  task :fortnightly_harvest, [:starting_author_id, :ending_author_id] => :environment do |t, args|
    args.with_defaults(:starting_author_id => 1, :ending_author_id => -1)
    starting_author_id = (args[:starting_author_id]).to_i
    ending_author_id = (args[:ending_author_id]).to_i
    harvester.harvest_pubs_for_all_authors(starting_author_id, ending_author_id)
    #CapAuthorshipMailer.welcome_email("harvest complete").deliver
  end

  desc "Harvest high priority faculty using the name-only query"
  task :faculty_harvest, [:path_to_ids] => :environment do |t, args|
    harvester.use_middle_name = false
    ids = IO.readlines(args[:path_to_ids]).map {|l| l.strip}
    harvester.harvest_pubs_for_author_ids ids
  end

  desc "Harvest using a directory full of Web Of Science bibtex query results"
  task :wos_harvest, [:path_to_bibtex] => :environment do |t, args|
    harvester.harvest_from_directory_of_wos_id_files args[:path_to_bibtex]
  end
end
