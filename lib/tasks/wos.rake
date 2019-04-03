namespace :wos do
  # @example rake wos:assign_uids[98765] < input.txt
  desc 'Assign WoS records (via UIDs on STDIN) to a cap_profile_id'
  task :assign_uids, [:cap_profile_id] => :environment do |_t, args|
    author = Author.find_by(cap_profile_id: args[:cap_profile_id])
    raise "Could not find Author by cap_profile_id: #{args[:cap_profile_id]}." if author.nil?
    puts "Reading WosUIDs from STDIN..."
    uids = STDIN.read.split("\n").each(&:strip!).select(&:present?)
    abort 'No records read from STDIN' if uids.blank?
    puts "#{uids.count} UIDs to assign to Author #{author.id} (cap_profile_id: #{author.cap_profile_id})"
    new_uids = WebOfScience.harvester.process_uids(author, uids)
    puts "#{new_uids.count} newly associated Contributions"
  end

  desc 'Harvest from Web of Science, for all authors, for all time'
  task harvest_authors: :environment do
    WebOfScience.harvester.harvest_all
  end

  # Note, possible values for symbolicTimeSpan (not well documented in WoS API documentation)
  # "xweek" where x > 1 and < 53
  # "xyear" where x => 1 and < ?
  desc 'Update harvest from Web of Science, for all authors'
  task :harvest_authors_update, [:symbolicTimeSpan] => :environment do |_t, args|
    options = args.with_defaults(symbolicTimeSpan: Settings.WOS.regular_harvest_timeframe)
    WebOfScience.harvester.harvest_all(options)
  end

  desc 'Harvest from Web of Science, for one author'
  task :harvest_author, [:cap_profile_id, :symbolicTimeSpan] => :environment do |_t, args|
    author = Author.find_by(cap_profile_id: args[:cap_profile_id])
    raise "Could not find Author by cap_profile_id: #{args[:cap_profile_id]}." if author.nil?
    options = {}
    options[:symbolicTimeSpan] = args[:symbolicTimeSpan] if args[:symbolicTimeSpan].present?
    WebOfScience.harvester.process_author(author, options)
  end

  desc 'Retrieve and print links for a publication by WOS-UID or WosItemId'
  task :links, [:wos_id] => :environment do |_t, args|
    raise 'wos_id argument is required.' if args[:wos_id].blank?
    links = WebOfScience.links_client.links([args[:wos_id]], fields: Clarivate::LinksClient::ALL_FIELDS)
    puts JSON.pretty_generate(links)
  end

  desc 'Retrieve and print a single publication by WOS-UID or WosItemId'
  task :publication, [:wos_id] => :environment do |_t, args|
    raise 'wos_id argument is required.' if args[:wos_id].blank?
    records = WebOfScience.queries.retrieve_by_id([args[:wos_id]]).next_batch
    records.each(&:print) # XML documents
  end
end
