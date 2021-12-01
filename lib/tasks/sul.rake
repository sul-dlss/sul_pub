# frozen_string_literal: true

require 'csv'
require 'json'

namespace :sul do
  desc 'Export publications as csv'
  # bundle exec rake sul:export_pubs_csv['/tmp/output_file.csv','01/01/2013'] # parameters are output csv file, and date to go back to in format of mm/dd/yyyy
  task :export_pubs_csv, %i[output_file date_since] => :environment do |_t, args|
    output_file = args[:output_file]
    date_since = args[:date_since]
    raise unless output_file && date_since

    total_pubs = Contribution.where('created_at > ?', Date.strptime(date_since, '%m/%d/%Y')).count
    puts "Exporting all pubs to #{output_file} since date #{date_since}, found #{total_pubs} contributions to export"
    header_row = %w[pub_title pub_associated_author_last_name pub_associated_author_first_name
                    pub_associated_author_sunet pub_associated_author_employee_id pub_added_date apa_citation]
    CSV.open(output_file, 'wb') do |csv|
      csv << header_row
      Contribution.where('created_at > ?', Date.strptime(date_since, '%m/%d/%Y')).find_each do |contribution|
        pub = contribution.publication
        author = contribution.author
        csv << [pub.title, author.last_name, author.first_name, author.sunetid, author.university_id,
                contribution.created_at, pub.pub_hash[:apa_citation]]
      end
    end
    end_time = Time.zone.now
    puts "Total: #{total_pubs}. Output file: #{output_file}. Ended at #{end_time}."
  end

  desc 'Export publications pub_hashes as json'
  # bundle exec rake sul:export_pubs_json['/tmp/output_folder',1000]
  # parameters are output folder and limit (defaults to 1000)
  # This task will output pub_hashes for publications into json files (one per pub) into the folder specified
  # Random sampling is used to select the publications.
  task :export_pubs_json, %i[output_folder limit] => :environment do |_t, args|
    output_folder = args[:output_folder]
    limit = args[:limit].to_i || 1000
    raise 'missing require params' unless output_folder

    publication_ids = Publication.ids.shuffle.take(limit)
    puts "Exporting limit of #{limit} pubs to #{output_folder}"
    total_pubs = 0

    FileUtils.mkdir_p(output_folder)
    publication_ids.each do |pub_id|
      pub = Publication.select(:id, :pub_hash).find(pub_id)
      File.open(File.join(output_folder, "publication-#{pub.id}.json"), 'w') { |f| f.write(JSON.pretty_generate(pub.pub_hash)) }
      total_pubs += 1
    end
    end_time = Time.zone.now
    puts "Total: #{total_pubs}. Output folder: #{output_folder}. Ended at #{end_time}."
  end

  desc 'Validate publications pub_hashes'
  # bundle exec rake sul:validate_pub_hash['/tmp/output_folder',1000]
  # parameters are output folder and limit (defaults to 1000)
  # This task will validate pub_hashes for publications. Publications with errors will be written to files (one per pub) into the folder specified
  # Use a different date and limit to fetch different samples
  task :validate_pub_hash, %i[output_folder limit] => :environment do |_t, args|
    output_folder = args[:output_folder]
    limit = args[:limit].to_i || 1_000_000
    raise 'missing require params' unless output_folder

    publications = Publication.select(:id, :pub_hash).limit(limit)
    puts "Exporting limit of #{limit} pubs to #{output_folder}"
    total_pubs = 0

    FileUtils.mkdir_p(output_folder)
    publications.find_each do |pub|
      errors = PubHashValidator.validate(pub.pub_hash)
      next if errors.empty?

      File.open(File.join(output_folder, "publication-#{pub.id}.json"), 'w') do |f|
        errors.each { |error| f.write("Error: #{error}\n") }
        f.write("\n\n")
        f.write(JSON.pretty_generate(pub.pub_hash))
      end
      total_pubs += 1
    end
    end_time = Time.zone.now
    puts "Total: #{total_pubs}. Output folder: #{output_folder}. Ended at #{end_time}."
  end

  desc 'Export publications for specific authors as csv'
  # exports all publications for the given sunets in a 'new' or 'approved' state after the date specified
  # input csv file should have a column with a header of 'SUNetID' containing the sunetid of interest
  # bundle exec rake sul:export_pubs_for_authors_csv['/tmp/input_file.csv','/tmp/output_file.csv','01/01/2013']
  # parameters are input csv file with sunets, output csv file, and date to go back to in format of mm/dd/yyyy
  task :export_pubs_for_authors_csv, %i[input_file output_file date_since] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    date_since = args[:date_since]
    raise 'missing required params' unless output_file && input_file && Time.zone.parse(date_since)
    raise 'missing input csv' unless File.file? input_file

    rows = CSV.parse(File.read(input_file), headers: true)
    total_authors = rows.size
    total_pubs = 0
    start_time = Time.zone.now
    puts "Exporting all pubs for #{total_authors} authors to #{output_file} since date #{date_since}.  Started at #{start_time}."
    header_row = %w[pub_title pmid doi publisher journal mesh pub_year provenance pub_associated_author_last_name
                    pub_associated_author_first_name pub_associated_author_sunet pub_associated_author_employee_id
                    author_list sunet_list publication_status pub_harvested_date apa_citation]
    CSV.open(output_file, 'wb') do |csv|
      csv << header_row
      rows.each_with_index do |row, i|
        sunet = row['SUNetID']
        message = "#{i + 1} of #{total_authors} : #{sunet}"
        author = Author.find_by(sunetid: sunet)
        if author
          contributions = Contribution.where("author_id = ? and status in ('new','approved') and created_at > ?",
                                             author.id, Time.zone.parse(date_since))
          puts "#{message} : #{contributions.size} publications"
          contributions.each do |contribution|
            pub = contribution.publication
            total_pubs += 1
            author_list = if pub.pub_hash[:author]
                            Csl::RoleMapper.send(:parse_authors, pub.pub_hash[:author]).map do |a|
                              "#{a['family']}, #{a['given']}"
                            end.join('; ')
                          else
                            ''
                          end
            sunet_list = pub.contributions.where("status in ('new','approved') and created_at > ?",
                                                 Time.zone.parse(date_since)).map do |c|
              c.author.sunetid
            end.compact.reject(&:empty?).join('; ')
            doi = pub.pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'doi' }.compact.join
            pmid = pub.pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'pmid' }.compact.join
            journal = pub.pub_hash[:journal] ? pub.pub_hash[:journal][:name] : ''
            mesh = if pub.pub_hash[:mesh_headings]
                     pub.pub_hash[:mesh_headings].map do |h|
                       h[:descriptor][0][:name]
                     end.compact.reject(&:empty?).join('; ')
                   else
                     ''
                   end
            csv << [pub.title, pmid, doi, pub.pub_hash[:publisher], journal, mesh, pub.pub_hash[:year],
                    pub.pub_hash[:provenance], author.last_name, author.first_name, author.sunetid, author.university_id,
                    author_list, sunet_list, contribution.status, contribution.created_at, pub.pub_hash[:apa_citation]]
          end
        else
          puts "#{message} : ERROR - not found in database"
        end
      end
    end
    end_time = Time.zone.now
    puts "Total: #{total_pubs}. Output file: #{output_file}. Ended at #{end_time}.  Total time: #{((end_time - start_time) / 60.0).round(1)} minutes."
  end

  desc 'Update pub_hash or authorship for all pubs'
  # bundle exec rake sul:update_pubs['rebuild_pub_hash'] # for pub hash rebuild
  # bundle exec rake sul:update_pubs['rebuild_authorship'] # for authorship rebuild
  task :update_pubs, [:method] => :environment do |_t, args|
    logger = Logger.new(Rails.root.join('log/update_pubs.log'))
    method = args[:method] || 'rebuild_pub_hash' # default to rebuilding pub_hash, could also rebuild_authorship
    raise "Method #{method} not defined" unless Publication.new.respond_to? method

    $stdout.sync = true # flush output immediately
    include ActionView::Helpers::NumberHelper # for nice display output and time computations in output
    include ActionView::Helpers::DateHelper
    total_pubs = Publication.count
    error_count = 0
    success_count = 0
    start_time = Time.zone.now
    output_each = 500
    max_errors = 500
    message = "Calling #{method} for #{number_with_delimiter(total_pubs)} publications.  Started at #{start_time}.  " \
      "Status update shown each #{output_each} publications."
    puts message
    logger.info message
    Publication.find_each.with_index do |pub, index|
      current_time = Time.zone.now
      elapsed_time = current_time - start_time
      avg_time_per_pub = elapsed_time / (index + 1)
      total_time_remaining = (avg_time_per_pub * (total_pubs - index)).floor
      if index % output_each == 0 # provide some feedback every X pubs
        message = "...#{current_time}: on publication #{number_with_delimiter(index + 1)} of #{number_with_delimiter(total_pubs)} : " \
          "~ #{distance_of_time_in_words(start_time, start_time + total_time_remaining.seconds)} left"
        logger.info message
      end
      begin
        pub.send(method)
        pub.save if pub.changed?
        success_count += 1
      rescue StandardError => e
        message = "*****ERROR on publication ID #{pub.id}: #{e.message}"
        puts message
        logger.error message
        error_count += 1
      end
      if error_count > max_errors
        message = "Halting: Maximum number of errors #{max_errors} reached"
        logger.error message
        raise message
      end
    end
    end_time = Time.zone.now
    message = "Total: #{number_with_delimiter(total_pubs)}.  Successful: #{success_count}.  Error: #{error_count}.  " \
      "Ended at #{end_time}. Total time: #{distance_of_time_in_words(end_time, start_time)}"
    puts message
    logger.info message
  end

  desc 'Fetch times-cited numbers given a list of DOIs'
  # bundle exec rake sul:times_cited['/tmp/list_of_dois.csv','/tmp/results.csv'] # pass in a CSV file with a list of DOIs with a column of "doi"
  task :times_cited, %i[input_file output_file] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    raise 'missing required params' unless output_file && input_file
    raise 'missing input csv' unless File.file? input_file

    rows = CSV.parse(File.read(input_file), headers: true)
    total_pubs = rows.size
    start_time = Time.zone.now
    error_count = 0
    doi_count = 0
    puts "Exporting times cited for all #{total_pubs} pubs.  Started at #{start_time}."
    header_row = %w[doi wos_uid title journal year authors times_cited]
    CSV.open(output_file, 'wb') do |csv|
      csv << header_row
      rows.each_with_index do |row, i|
        doi = Identifiers::DOI.extract(row['doi']).first
        year = row['year']
        message = "#{i + 1} of #{total_pubs} : #{doi}"
        if doi # valid doi found
          doi_count += 1
          begin
            results = WebOfScience.queries.search_by_doi(doi).next_batch.to_a
            if results.size == 1
              wos_uid = results[0].uid
              title = results[0].titles['item']
              journal = results[0].titles['source']
              authors = results[0].authors.map { |a| a['full_name'] }.join('; ')
              times_results = WebOfScience.links_client.links([wos_uid], fields: %w[timesCited])
              times_cited = times_results[wos_uid]['timesCited']
            else
              wos_uid = 'wos_uid not found'
              times_cited = title = journal = authors = ''
            end
            csv << [doi, wos_uid, title, journal, year, authors, times_cited]
          rescue StandardError => e # some exception occurred
            error_count += 1
            message = "*****ERROR on #{doi}: #{e.message}"
          end
        else # no valid DOI found
          csv << [row['doi'], 'doi not valid', '', '', '', '', '']
        end
        puts message
      end
    end
    end_time = Time.zone.now
    puts "Total: #{total_pubs}. Output file: #{output_file}. Ended at #{end_time}.  #{doi_count} had valid DOIs.  " \
      "#{error_count} errors occurred. Total time: #{((end_time - start_time) / 60.0).round(1)} minutes."
  end

  desc 'Export author data as json'
  # bundle exec rake sul:author_export['tmp/authors.csv','tmp/results.json']
  # export all authors metadata given a list of sunets or cap_profile_ids, including the alternate identity data
  # input csv file should have a column with a header of 'sunetid' or 'cap_profile_id' containing the sunetid or cap_profile_id of interest
  #  if both are supplied, sunetid is used
  task :author_export, %i[input_file output_file] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    raise 'missing required params' unless output_file && input_file
    raise 'missing input csv' unless File.file? input_file

    rows = CSV.parse(File.read(input_file), headers: true)
    total_authors = rows.size
    output_data = []
    puts "Exporting all author information for #{total_authors} authors to #{output_file}"
    rows.each_with_index do |row, i|
      sunet = row['sunetid']
      cap_profile_id = row['cap_profile_id']
      puts "#{i + 1} of #{total_authors} : sunet: #{sunet} / cap_profile_id: #{cap_profile_id}"
      author = if sunet
                 Author.find_by(sunetid: sunet)
               else
                 Author.find_by(cap_profile_id: cap_profile_id)
               end
      if author
        author_info = { first_name: author.first_name, middle_name: author.middle_name, last_name: author.last_name,
                        email: author.emails_for_harvest, sunet: author.sunetid, cap_profile_id: author.cap_profile_id }
        author_info[:identities] = author.author_identities.map do |ai|
          { first_name: ai.first_name, middle_name: ai.middle_name, last_name: ai.last_name, email: ai.email, institution: ai.institution }
        end
        output_data << author_info
      else
        puts "***** ERROR: Sunet: #{sunet}, cap_profile_id: #{cap_profile_id} not found, skipping"
      end
    end
    File.open(output_file, 'w') { |f| f.write(JSON.pretty_generate(output_data)) }
  end

  desc 'Custom SMCI export of profile and non-profile authors report'
  # bundle exec rake sul:smci_export['tmp/authors.csv','tmp/results.csv','1/1/2000','10year']
  # bundle exec rake sul:smci_export['tmp/authors.csv','tmp/results.csv',,] # for all time
  # see lib/smci_report.rb for full details of parameters and usage
  task :smci_export, %i[input_file output_file date_since time_span] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    date_since = args[:date_since]
    time_span = args[:time_span]
    smci = SMCIReport.new(input_file: input_file, output_file: output_file, date_since: date_since,
                          time_span: time_span)
    smci.run
  end

  # bundle exec rake sul:stanford_orcid_users['tmp/results.csv']
  # Query the sul_pub database for all people with an ORCIDID (i.e. that have
  # gone through the Stanford integration and were returned via the MaIS API)
  # and also query for potential Stanford people with ORCIDIDs via the ORCID API.
  # Get the difference between these two sets which represents people with ORCIDs
  # that are not in our system.
  desc 'Export all Stanford users with ORCIDs'
  task :stanford_orcid_users, %i[output_file] => :environment do |_t, args|
    output_file = args[:output_file]

    # active stanford users who have gone through the Stanford ORCID integration
    users = Author.where.not(orcidid: nil).where(active_in_cap: true)
    total_stanford = users.size
    orcidids_stanford = users.map(&:orcidid)
    puts "Number of active Stanford users who have gone through integration: #{total_stanford}"

    # an ORCID API query that searches for Stanford people
    query = '(ringgold-org-id:6429)OR(orgname="Stanford%20University")OR("grid.168010.e")OR(email=*.stanford.edu)'
    orcid_client = Orcid::Client.new
    response = orcid_client.search(query)
    total_orcid = response['num-found']
    orcidids_api = response['result'].map { |result| result['orcid-identifier']['uri'] }
    puts "ORCID API Query: #{query}"
    puts "Number of ORCIDs returned from ORCID API: #{total_orcid}"

    # users returned from the ORCID API - users who have gone through ORCID integration
    orcidids_diff = orcidids_api - orcidids_stanford
    total_diff = orcidids_diff.size
    puts "Number of users returned from the ORCID API - known Stanford ORCID users: #{total_diff}"

    header_row = %w[orcidid name last_name first_name sunet cap_profile_id scope num_works_pushed integration_last_updated]
    CSV.open(output_file, 'wb') do |csv|
      csv << header_row
      # first write out all of the known stanford users
      puts 'writing Stanford integration users'
      users.each_with_index do |user, i|
        puts "#{i + 1} of #{total_stanford}: #{user.sunetid} | #{user.orcidid}"
        mais_user = Mais::Client.new.fetch_orcid_user(sunetid: user.sunetid)
        scope = if mais_user.update?
                  'update'
                else
                  'read'
                end
        num_works_pushed = user.contributions.where.not(orcid_put_code: nil).size
        csv << [user.orcidid, "#{user.cap_first_name} #{user.cap_last_name}", user.cap_last_name, user.cap_first_name,
                user.sunetid, user.cap_profile_id, scope, num_works_pushed, mais_user.last_updated.to_date]
      end

      # next write out all of the ORCID API users that were not already in the Stanford list
      puts 'writing ORCID API users'
      orcidids_diff.each_with_index do |orcidid, i|
        puts "#{i + 1} of #{total_diff}: #{orcidid}"
        name = orcid_client.fetch_name(orcidid)
        csv << [orcidid, name.join(' '), name[1], name[0], '', '', '', '', '']
      end
    end
    puts
    puts "Written to #{output_file}"
  end

  desc 'Run ORCID query and export results with names'
  # query = '(ringgold-org-id:6429)OR(orgname="Stanford%20University")OR("grid.168010.e")OR(email=*.stanford.edu)'
  # bundle exec rake sul:orcid_query[query,'tmp/results.csv']
  # Run a query against the ORCID API, then export ORCIDs and Names into CSV
  task :orcid_query, %i[query output_file] => :environment do |_t, args|
    query = args[:query]
    output_file = args[:output_file]
    orcid_client = Orcid::Client.new
    response = orcid_client.search(query)
    total = response['num-found']
    puts "Query: #{query}"
    puts "Num results: #{total}"
    puts
    header_row = %w[orcidid full_name last_name first_name]
    CSV.open(output_file, 'wb') do |csv|
      csv << header_row
      response['result'].each_with_index do |result, i|
        orcidid = result['orcid-identifier']['uri']
        puts "#{i + 1} of #{total}: #{orcidid}"
        name = orcid_client.fetch_name(orcidid)
        csv << [orcidid, name.join(' '), name[1], name[0]]
      end
    end
    puts
    puts "Written to #{output_file}"
  end
end
