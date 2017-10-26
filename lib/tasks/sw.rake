namespace :sw do
  def harvester
    @harvester ||= begin
      h = ScienceWireHarvester.new
      Signal.trap('USR1') do
        harvester.debug = true
      end
      h
    end
  end

  # rake sw:fortnightly_harvest[1, 5]
  desc 'Harvest from sciencewire by email or known sciencewire pub ids'
  task :fortnightly_harvest, [:starting_author_id, :ending_author_id] => :environment do |_t, args|
    args.with_defaults(starting_author_id: 1, ending_author_id: -1)
    starting_author_id = (args[:starting_author_id]).to_i
    ending_author_id = (args[:ending_author_id]).to_i
    harvester.harvest_pubs_for_all_authors(starting_author_id, ending_author_id)
    # CapAuthorshipMailer.welcome_email("harvest complete").deliver
  end

  desc 'Harvest (with multiple processes) from sciencewire by email or known sciencewire pub ids'
  task parallel_harvest: :environment do
    harvester.harvest_pubs_for_all_authors_parallel
  end

  desc 'Harvest high priority faculty using the name-only query'
  task :faculty_harvest, [:path_to_ids] => :environment do |_t, args|
    harvester.use_middle_name = false
    ids = IO.readlines(args[:path_to_ids]).map(&:strip)
    harvester.harvest_pubs_for_author_ids ids
  end

  desc 'Harvest for a cap_profile_id using the name-only query'
  task :cap_profile_harvest, [:cap_profile_id] => :environment do |_t, args|
    harvester.use_middle_name = false
    cap_profile_id = (args[:cap_profile_id]).to_i
    author = Author.where(cap_profile_id: cap_profile_id).first
    author ||= Author.fetch_from_cap_and_create(cap_profile_id)
    harvester.harvest_pubs_for_author_ids author.id
    # Summarize the publications harvested
    pubs = Contribution.where(author_id: author.id).map {|c| c.publication }
    pubs.each {|p| puts "publication #{p.id}: #{p.pub_hash[:apa_citation]}"}
  end

  desc 'Harvest using a directory full of Web Of Science bibtex query results'
  task :wos_harvest, [:path_to_bibtex] => :environment do |_t, args|
    harvester.harvest_from_directory_of_wos_id_files args[:path_to_bibtex]
  end

  desc 'Harvest for a given sunetid and a json-file with an array of WoS ids'
  task :wos_sunetid_json, [:sunetid, :path_to_json] => :environment do |_t, args|
    harvester.harvest_for_sunetid_with_wos_json args[:sunetid], args[:path_to_json]
  end

  desc 'Harvest using a text report file of WOS ids and cap_profile_ids'
  task :wos_profile_id_report, [:path_to_report] => :environment do |_t, args|
    harvester.harvest_from_wos_id_cap_profile_id_report args[:path_to_report]
  end

  desc 'Compare publications (IDs) returned by APIs for an Author identified by their name [last,first,middle]'
  task :wos_publications_for_name, [:last, :first, :middle] => :environment do |_t, args|
    fail "last name argument is required" unless args[:last].present?
    fail "first name argument is required" unless args[:first].present?
    sciencewire_harvester = ScienceWireHarvester.new
    institution = sciencewire_harvester.default_institution
    author_name = ScienceWire::AuthorName.new(args[:last], args[:first], args[:middle])
    attribs = ScienceWire::AuthorAttributes.new(author_name, '', [], institution)
    puts "Querying ScienceWire for #{author_name.inspect}"
    ids = ScienceWire::HarvestBroker.new(nil, sciencewire_harvester).ids_from_dumb_query(attribs)
    puts "\n" << ids.sort.join("\n") if ids.count > 0
    puts "\nQuerying WebOfScience for #{author_name.full_name}"
    wos_queries = WebOfScience::Queries.new(WebOfScience::Client.new(Settings.WOS.AUTH_CODE))
    records = wos_queries.search_by_name(author_name.full_name, [institution.name])
    uids = records.uids.sort
    puts uids.join("\n")
    puts "\n#{ids.count} ScienceWire IDs"
    puts "#{uids.count} WebOfScience IDs"
    wos_ids     = uids.select { |id| id =~ /^WOS:/ }.map { |id| id[4..-1] } # match and strip prefix
    medline_ids = uids.select { |id| id =~ /^MEDLINE:/ }.map { |id| id[8..-1] } # match and strip prefix
    wos_hits     = PublicationIdentifier.where(identifier_type: 'WoSItemID', identifier_value: wos_ids)
    medline_hits = PublicationIdentifier.where(identifier_type: 'PMID', identifier_value: medline_ids)
    swids_from_wos     = wos_hits.map { |pub_id| pub_id.publication.sciencewire_id }.compact
    swids_from_medline = medline_hits.map { |pub_id| pub_id.publication.sciencewire_id }.compact
    counts = Hash.new { 0 }
    counts[:medline_intersection] = (ids & swids_from_medline).count
    counts[:wos_intersection]     = (ids & swids_from_wos).count
    puts "\t#{medline_ids.count} MEDLINE IDs: #{swids_from_medline.count} of #{medline_hits.count} matching PubIDs in DB have SW ID"
    puts "\t#{wos_ids.count} WOS IDs: #{swids_from_wos.count} of #{wos_hits.count} matching PubIDs in DB have SW ID"
    puts "\nTotal INTERSECTION with ScienceWire IDs (#{counts.values.sum} of #{ids.count}):"
    puts "\t#{counts[:medline_intersection]} MEDLINE"
    puts "\t#{counts[:wos_intersection]} WOS"
    unmatched = ids - swids_from_medline - swids_from_wos
    puts "\n#{unmatched.count} Unmatched ScienceWire IDs:\n" << unmatched.join("\n") unless unmatched.empty?
  end

  desc 'Retrieve and print a single publication by WOS id: wos_publication[wos_id]'
  task :wos_publication, [:wos_id] => :environment do |_t, args|
    fail "wos_id argument is required." unless args[:wos_id].present?
    wos_ids = [args[:wos_id]]
    sciencewire_client = ScienceWireClient.new
    doc = sciencewire_client.get_full_sciencewire_pubs_for_wos_ids(wos_ids)
    puts doc # XML document
  end

  desc 'Harvest for a cap_profile_id with alternate names'
  task :cap_profile_harvest_alt_names, [:cap_profile_id] => :environment do |_t, args|
    harvester.use_author_identities = true
    cap_profile_id = (args[:cap_profile_id]).to_i
    author = Author.where(cap_profile_id: cap_profile_id).first
    author ||= Author.fetch_from_cap_and_create(cap_profile_id)
    harvester.harvest_pubs_for_author_ids author.id
    pubs = Contribution.where(author_id: author.id).map {|c| c.publication }.each do |p|
      puts "publication #{p.id}: #{p.pub_hash[:apa_citation]}"
    end
    puts "Number of publications #{pubs.count}"
  end
end
