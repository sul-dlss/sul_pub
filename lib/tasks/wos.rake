namespace :wos do
  desc 'Harvest from Web of Science, for all authors'
  task harvest_authors: :environment do
    WebOfScience.harvester.harvest_all
  end

  desc 'Update harvest from Web of Science, for all authors'
  task harvest_authors_update: :environment do
    WebOfScience.harvester.harvest_all(update: true)
  end

  desc 'Harvest from Web of Science, for one author'
  task :harvest_author, [:cap_profile_id] => :environment do |_t, args|
    author = Author.find_by(cap_profile_id: args[:cap_profile_id])
    raise "Could not find Author by cap_profile_id: #{args[:cap_profile_id]}." if author.nil?
    WebOfScience.harvester.process_author(author)
  end

  desc 'Retrieve and print links for a publication by WOS-UID or WosItemId'
  task :links, [:wos_id] => :environment do |_t, args|
    raise 'wos_id argument is required.' if args[:wos_id].blank?
    wos_ids = [args[:wos_id]]
    links = WebOfScience.links_client.links(wos_ids, fields: Clarivate::LinksClient::ALL_FIELDS)
    puts JSON.pretty_generate(links)
  end

  desc 'Retrieve and print a single publication by WOS-UID or WosItemId'
  task :publication, [:wos_id] => :environment do |_t, args|
    raise 'wos_id argument is required.' if args[:wos_id].blank?
    wos_ids = [args[:wos_id]]
    records = WebOfScience.queries.retrieve_by_id(wos_ids)
    records.each(&:print) # XML documents
  end
end
