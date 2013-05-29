namespace :sw do
  desc "harvest from sciencewire by email or known sciencewire pub ids"
  task :harvest => :environment do
    SciencewireSourceRecord.harvest_pubs_from_sciencewire_for_all_authors
  end
end
