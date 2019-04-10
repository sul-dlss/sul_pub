namespace :harvest do
  desc 'Harvest from all sources, for all authors, for all time'
  task all_authors: :environment do
    AllSources.harvester.harvest_all
  end

  desc 'Update harvest from all sources, for all authors, using default update timeframes'
  task all_authors_update: :environment do
    options = {
      symbolicTimeSpan: Settings.WOS.regular_harvest_timeframe,
      relDate: Settings.PUBMED.regular_harvest_timeframe
    }
    AllSources.harvester.harvest_all(options)
  end

  desc 'Harvest from all sources for single author, for all time'
  task :author, [:cap_profile_id] => :environment do |_t, args|
    author = Author.find_by(cap_profile_id: args[:cap_profile_id])
    raise "Could not find Author by cap_profile_id: #{args[:cap_profile_id]}." if author.nil?
    AllSources.harvester.process_author(author)
  end

  desc 'Harvest from all sources for single author, using default update timeframes'
  task :author_update, [:cap_profile_id] => :environment do |_t, args|
    author = Author.find_by(cap_profile_id: args[:cap_profile_id])
    raise "Could not find Author by cap_profile_id: #{args[:cap_profile_id]}." if author.nil?
    options = {
      symbolicTimeSpan: Settings.WOS.regular_harvest_timeframe,
      relDate: Settings.PUBMED.regular_harvest_timeframe
    }
    AllSources.harvester.process_author(author, options)
  end
end
