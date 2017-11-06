namespace :wos do
  desc 'Retrieve and print links for a publication by WOS-UID or WosItemId'
  task :links, [:wos_id] => :environment do |_t, args|
    raise 'wos_id argument is required.' if args[:wos_id].blank?
    wos_ids = [args[:wos_id]]
    links = WOS.links_client.links(wos_ids, fields: Clarivate::LinksClient::ALL_FIELDS)
    puts JSON.pretty_generate(links)
  end

  desc 'Retrieve and print a single publication by WOS-UID or WosItemId'
  task :publication, [:wos_id] => :environment do |_t, args|
    raise 'wos_id argument is required.' if args[:wos_id].blank?
    wos_ids = [args[:wos_id]]
    records = WOS.queries.retrieve_by_id(wos_ids)
    records.each(&:print) # XML documents
  end
end
