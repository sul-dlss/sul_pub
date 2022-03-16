# frozen_string_literal: true

require 'csv'
require 'json'
require 'fileutils'

namespace :sul do
  desc 'ORCID integration stats'
  # Produce statistics about the number of profiles users who have gone through ORCID integration and the scope authorized
  # bundle exec rake sul:orcid_integration_stats
  task orcid_integration_stats: :environment do |_t, _args|
    puts 'Fetching stats from MaIS ORCID API...'
    orcid_users = Mais.client.fetch_orcid_users
    # NOTE: that the `fetch_orcid_users` command will returned some duplicated sunets, because it returns a recent history
    # of all changes for that sunet, with the last entry being the current scope (i.e. if they change scope, they may be returned twice)
    sunets = orcid_users.map(&:sunetid).uniq

    # determine how many have authorized write vs read
    # note that the `fetch_orcid_user` for a single user will return the latest scope for that user (no dupes)
    scopes = { read: 0, write: 0 }
    sunets.each { |sunetid| Mais::Client.new.fetch_orcid_user(sunetid: sunetid).update? ? scopes[:write] += 1 : scopes[:read] += 1 }
    puts "Report run: #{Time.zone.now}"
    puts "Total users: #{sunets.size}"
    puts "Total users with read only scope: #{scopes[:read]}"
    puts "Total users with read/write scope: #{scopes[:write]}"
  end

  desc 'Run publication import stats'
  # Produce statistics about the number of publications imported, number of unique authors, and numbers in each state
  #  in the specified time period
  # bundle exec rake sul:publication_import_stats['1/1/2022','1/31/2022']
  task :publication_import_stats, %i[date1 date2] => :environment do |_t, args|
    start_date = Date.strptime(args[:date1], '%m/%d/%Y')
    end_date = Date.strptime(args[:date2], '%m/%d/%Y')
    new_author_count = Author.where('created_at > ? and created_at < ?', start_date, end_date).where(active_in_cap: true, cap_import_enabled: true).count
    total_publication_count = Contribution.where('created_at > ? and created_at < ?', start_date, end_date).count
    total_unique_publication_count = Contribution.select(:author_id).where('created_at > ? and created_at < ?', start_date, end_date).distinct.count
    denied_publications = Contribution.where('created_at > ? and created_at < ? and status = ?', start_date, end_date, 'denied').count
    approved_publications = Contribution.where('created_at > ? and created_at < ? and status = ?', start_date, end_date, 'approved').count
    new_publications = Contribution.where('created_at > ? and created_at < ? and status = ?', start_date, end_date, 'new').count
    puts 'new_authors,total_pubs,total_unique_pubs,total_waiting,total_approved,total_denied,waiting_percent,precision_approved,precision_denied'
    output = "#{new_author_count}, #{total_publication_count}, #{total_unique_publication_count}, "
    output += "#{new_publications}, #{approved_publications}, #{denied_publications}, "
    if total_publication_count > 0
      reviewed_pubs_count = total_publication_count - new_publications
      output += "#{((new_publications.to_f / total_publication_count) * 100.0).round(1)}%, "
      output += "#{((approved_publications.to_f / reviewed_pubs_count) * 100.0).round(1)}%, "
      output += "#{((denied_publications.to_f / reviewed_pubs_count) * 100.0).round(1)}%"
    else
      output += '0%, 0%, 0%'
    end
    puts output
  end

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
      File.write(File.join(output_folder, "publication-#{pub.id}.json"), JSON.pretty_generate(pub.pub_hash))
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
            end.compact.compact_blank.join('; ')
            doi = pub.pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'doi' }.compact.join
            pmid = pub.pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'pmid' }.compact.join
            journal = pub.pub_hash[:journal] ? pub.pub_hash[:journal][:name] : ''
            mesh = if pub.pub_hash[:mesh_headings]
                     pub.pub_hash[:mesh_headings].map do |h|
                       h[:descriptor][0][:name]
                     end.compact.compact_blank.join('; ')
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

  desc 'Export author data'
  # bundle exec rake sul:author_export['tmp/authors.csv','tmp/results.json','json']
  # export all authors metadata given a list of sunets or cap_profile_ids, in either json or csv format
  # (including the alternate identity data if the format is json)
  # input csv file should have a column with a header of 'sunetid' or 'cap_profile_id' containing the sunetid or cap_profile_id of interest
  #  if both are supplied, sunetid is used
  #  output is either a csv file or a json file, depending on the format selected
  task :author_export, %i[input_file output_file file_format] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    file_format = args[:file_format]
    raise 'missing required params' unless output_file && input_file && file_format
    raise 'missing input csv' unless File.file? input_file
    raise 'invalid file format, must be json or csv' unless %w[json csv].include? file_format

    rows = CSV.parse(File.read(input_file), headers: true)
    total_authors = rows.size
    output_json_data = []
    header_row = %w[first_name middle_name last_name email sunetid cap_profile_id]
    CSV.open(output_file, 'wb') { |csv| csv << header_row } if file_format == 'csv'
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
        if file_format == 'json'
          author_info = { first_name: author.first_name, middle_name: author.middle_name, last_name: author.last_name,
                          email: author.emails_for_harvest, sunet: author.sunetid, cap_profile_id: author.cap_profile_id }
          author_info[:identities] = author.author_identities.map do |ai|
            { first_name: ai.first_name, middle_name: ai.middle_name, last_name: ai.last_name, email: ai.email, institution: ai.institution }
          end
          output_json_data << author_info
        else
          CSV.open(output_file, 'a') do |csv|
            csv << [author.first_name, author.middle_name, author.last_name,
                    author.emails_for_harvest, author.sunetid, author.cap_profile_id]
          end
        end
      else
        puts "***** ERROR: Sunet: #{sunet}, cap_profile_id: #{cap_profile_id} not found, skipping"
        CSV.open(output_file, 'a') { |csv| csv << ['', '', '', '', sunet, cap_profile_id] } if file_format == 'csv'
      end
    end
    File.write(output_file, JSON.pretty_generate(output_json_data)) if file_format == 'json'
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
    smci = SmciReport.new(input_file: input_file, output_file: output_file, date_since: date_since,
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

  desc 'Find sunets given first and last names'
  # bundle exec rake sul:lookup_sunet['tmp/names.csv', 'tmp/sunets.csv']
  # Given a list of names in CSV, split into first and last names and try to find matching SUNETs in the database, output to new csv file
  # input format is a CSV with a column called "full_name" which includes names in "FIRST LAST" format (no middle initials or other data)
  task :lookup_sunet, %i[input_file output_file] => :environment do |_t, args|
    input_file = args[:input_file]
    output_file = args[:output_file]
    puts "Input file: #{input_file}"
    puts
    header_row = %w[full_name SUNetID]
    CSV.open(output_file, 'wb') do |csv|
      csv << header_row
      rows = CSV.parse(File.read(input_file), headers: true)
      num_rows = rows.size
      puts "Found #{num_rows} rows of names"
      rows.each_with_index do |row, i|
        name = row['full_name']
        split_name = name.split
        first_name = split_name[0] # assume part of string before first space is first name
        last_name = split_name[1..].join(' ') # everything else is the last name (e.g. to deal with a case like "Peter de La Rossa")
        author = Author.find_by(cap_last_name: last_name, cap_first_name: first_name)
        sunetid = author ? author.sunetid : '*** NOT FOUND ***'
        csv << [name, sunetid]
        puts "#{i + 1} of #{num_rows} : #{name} : #{sunetid}"
      end
    end
    puts
    puts "Written to #{output_file}"
  end

  desc 'Output publication stats for active authors, then output all publications for each author'
  # Write out a CSV file with user_ids, cap_profile_ids, names, sunets, and queries.
  # Next make a directory for the author publication outputs in tmp and export their publications.
  # Only exports author who are active and have harvesting enabled.
  # Specify maximum number of authors to return and the minimum number of publications each must have to be returned.
  # Note that all publications for authors are exported, not just approved.
  # You will get a random subset of these authors up the maximum specified
  # Parameters that can be specified are maximum number of authors, minimum number of publications for each, and output file
  # Defaults are 100 authors, minimum of 5 publications, and output file = 'tmp/random_authors.csv'
  # Note that since only WoS publications are output, you may get less publications output than the min specified.
  # bundle exec rake sul:author_publications_report[100,5,'tmp/random_authors.csv']
  task :author_publications_report, %i[n min_pubs output_file] => :environment do |_t, args|
    n = args[:n].to_i || 100
    min_pubs =  args[:min_pubs].to_i || 5
    output_file = args[:output_file] || 'tmp/random_authors.csv'
    output_directory = 'tmp/author_reports'

    puts "Number of authors: #{n}"
    puts "Minimum number of pubs per author: #{min_pubs}"
    puts "Output file: #{output_file}"
    puts

    FileUtils.mkdir_p output_directory

    puts "... fetching random #{n} authors"
    user_ids = []
    max_id = Author.last.id
    while user_ids.size < n
      user = Author.find_by(id: rand(max_id))
      user_ids << user.id if user && user.active_in_cap == true && user.cap_import_enabled == true && user.contributions.size >= min_pubs
    end

    header_row = %w[author_id orcid cap_profile_id sunetid name num_publications query]
    CSV.open(output_file, 'wb') do |csv|
      csv << header_row
      user_ids.each_with_index do |user_id, i|
        puts "... exporting #{i + 1} of #{n}"
        author = Author.find(user_id)
        author_query = WebOfScience::QueryAuthor.new(author)
        query = author_query.name_query.send(:name_query)[:queryParameters][:userQuery]
        csv << [user_id, author.orcidid, author.cap_profile_id, author.sunetid, "#{author.first_name} #{author.last_name}", author.contributions.size, query]
        CSV.open("#{output_directory}/author_#{user_id}.csv", 'wb') do |csv_pubs|
          csv_pubs << %w[id doi wos_uid citation provenance status]
          author.contributions.each do |contrib|
            next unless contrib.publication.wos_pub? # only consider Web of Science publications

            doi = contrib.publication.publication_identifiers.where(identifier_type: 'doi')&.first&.identifier_value
            csv_pubs << [contrib.publication_id, doi, contrib.publication.wos_uid, contrib.publication.pub_hash[:apa_citation],
                         contrib.publication.pub_hash[:provenance], contrib.status]
          end
        end
      end
    end
    puts
    puts "Written to #{output_file}"
    puts "Publications per author exported to #{output_directory}"
  end
end
