require 'csv'
require 'json'

namespace :sul do
  desc 'Export publications as csv'
  # bundle exec rake sul:export_pubs_csv['/tmp/output_file.csv','01/01/2013'] # parameters are output csv file, and date to go back to in format of mm/dd/yyyy
  task :export_pubs_csv, [:output_file, :date_since] => :environment do |_t, args|
    output_file = args[:output_file]
    date_since = args[:date_since]
    raise unless output_file && date_since
    total_pubs = Contribution.where('created_at > ?', Date.strptime(date_since, '%m/%d/%Y')).count
    puts "Exporting all pubs to #{output_file} since date #{date_since}, found #{total_pubs} contributions to export"
    header_row = %w(pub_title pub_associated_author_last_name pub_associated_author_first_name pub_associated_author_sunet pub_associated_author_employee_id pub_added_date apa_citation)
    CSV.open(output_file, "wb") do |csv|
      csv << header_row
      Contribution.where('created_at > ?', Date.strptime(date_since, '%m/%d/%Y')).find_each do |contribution|
        pub = contribution.publication
        author = contribution.author
        csv << [pub.title, author.last_name, author.first_name, author.sunetid, author.university_id, contribution.created_at, pub.pub_hash[:apa_citation]]
      end
    end
    end_time = Time.zone.now
    puts "Total: #{total_pubs}. Output file: #{output_file}. Ended at #{end_time}."
  end

  desc 'Export publications for specific authors as csv'
  # exports all publications for the given sunets in a 'new' or 'approved' state after the date specified
  # input csv file should have a column with a header of 'SUNetID' containing the sunetid of interest
  # bundle exec rake sul:export_pubs_for_authors_csv['/tmp/input_file.csv','/tmp/output_file.csv','01/01/2013'] # parameters are input csv file with sunets, output csv file, and date to go back to in format of mm/dd/yyyy
  task :export_pubs_for_authors_csv, [:input_file, :output_file, :date_since] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    date_since = args[:date_since]
    raise "missing required params" unless output_file && input_file && Time.parse(date_since)
    raise "missing input csv" unless File.file? input_file
    rows = CSV.parse(File.read(input_file), headers: true)
    total_authors = rows.size
    total_pubs = 0
    start_time = Time.zone.now
    puts "Exporting all pubs for #{total_authors} authors to #{output_file} since date #{date_since}.  Started at #{start_time}."
    header_row = %w(pub_title pmid doi publisher journal mesh pub_year provenance pub_associated_author_last_name pub_associated_author_first_name pub_associated_author_sunet pub_associated_author_employee_id author_list sunet_list publication_status pub_harvested_date apa_citation)
    CSV.open(output_file, "wb") do |csv|
      csv << header_row
      rows.each_with_index do |row, i|
        sunet = row['SUNetID']
        message = "#{i + 1} of #{total_authors} : #{sunet}"
        author = Author.find_by(sunetid: sunet)
        if author
          contributions = Contribution.where("author_id = ? and status in ('new','approved') and created_at > ?", author.id, Time.parse(date_since))
          puts "#{message} : #{contributions.size} publications"
          contributions.each do |contribution|
            pub = contribution.publication
            total_pubs += 1
            author_list = pub.pub_hash[:author] ? Csl::RoleMapper.send(:parse_authors, pub.pub_hash[:author]).map { |a| "#{a['family']}, #{a['given']}" }.join('; ') : ''
            sunet_list = pub.contributions.where("status in ('new','approved') and created_at > ?", Time.parse(date_since)).map { |c| c.author.sunetid }.compact.reject(&:empty?).join('; ')
            doi = pub.pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'doi' }.compact.join
            pmid = pub.pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'pmid' }.compact.join
            journal = pub.pub_hash[:journal] ? pub.pub_hash[:journal][:name] : ''
            mesh = pub.pub_hash[:mesh_headings] ? pub.pub_hash[:mesh_headings].map { |h| h[:descriptor][0][:name] }.compact.reject(&:empty?).join('; ') : ''
            csv << [pub.title, pmid, doi, pub.pub_hash[:publisher], journal, mesh, pub.pub_hash[:year], pub.pub_hash[:provenance], author.last_name, author.first_name, author.sunetid, author.university_id, author_list, sunet_list, contribution.status, contribution.created_at, pub.pub_hash[:apa_citation]]
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
    logger = Logger.new(Rails.root.join('log', 'update_pubs.log'))
    method = args[:method] || "rebuild_pub_hash" # default to rebuilding pub_hash, could also rebuild_authorship
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
    message = "Calling #{method} for #{number_with_delimiter(total_pubs)} publications.  Started at #{start_time}.  Status update shown each #{output_each} publications."
    puts message
    logger.info message
    Publication.find_each.with_index do |pub, index|
      current_time = Time.zone.now
      elapsed_time = current_time - start_time
      avg_time_per_pub = elapsed_time / (index + 1)
      total_time_remaining = (avg_time_per_pub * (total_pubs - index)).floor
      if index % output_each == 0 # provide some feedback every X pubs
        message = "...#{current_time}: on publication #{number_with_delimiter(index + 1)} of #{number_with_delimiter(total_pubs)} : ~ #{distance_of_time_in_words(start_time, start_time + total_time_remaining.seconds)} left"
        logger.info message
      end
      begin
        pub.send(method)
        pub.save if pub.changed?
        success_count += 1
      rescue => e
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
    message = "Total: #{number_with_delimiter(total_pubs)}.  Successful: #{success_count}.  Error: #{error_count}.  Ended at #{end_time}. Total time: #{distance_of_time_in_words(end_time, start_time)}"
    puts message
    logger.info message
  end

  desc 'Fetch times-cited numbers given a list of DOIs'
  # bundle exec rake sul:times_cited['/tmp/list_of_dois.csv','/tmp/results.csv'] # pass in a CSV file with a list of DOIs with a column of "doi"
  task :times_cited, [:input_file, :output_file] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    raise "missing required params" unless output_file && input_file
    raise "missing input csv" unless File.file? input_file
    rows = CSV.parse(File.read(input_file), headers: true)
    total_pubs = rows.size
    start_time = Time.zone.now
    error_count = 0
    doi_count = 0
    puts "Exporting times cited for all #{total_pubs} pubs.  Started at #{start_time}."
    header_row = %w(doi wos_uid title journal year authors times_cited)
    CSV.open(output_file, "wb") do |csv|
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
              times_results = WebOfScience.links_client.links([wos_uid], fields: %w(timesCited))
              times_cited = times_results[wos_uid]['timesCited']
            else
              wos_uid = 'wos_uid not found'
              times_cited = title = journal = authors = ''
            end
            csv << [doi, wos_uid, title, journal, year, authors, times_cited]
          rescue => e # some exception occurred
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
    puts "Total: #{total_pubs}. Output file: #{output_file}. Ended at #{end_time}.  #{doi_count} had valid DOIs.  #{error_count} errors occurred. Total time: #{((end_time - start_time) / 60.0).round(1)} minutes."
  end

  desc 'Export author data as json'
  # bundle exec rake sul:author_export['tmp/authors.csv','tmp/results.json']
  # export all authors metadata given a list of sunets or cap_profile_ids, including the alternate identity data
  # input csv file should have a column with a header of 'sunetid' or 'cap_profile_id' containing the sunetid or cap_profile_id of interest
  #  if both are supplied, sunetid is used
  task :author_export, [:input_file, :output_file] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    raise "missing required params" unless output_file && input_file
    raise "missing input csv" unless File.file? input_file
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
        author_info = { first_name: author.first_name, middle_name: author.middle_name, last_name: author.last_name, email: author.emails_for_harvest, sunet: author.sunetid, cap_profile_id: author.cap_profile_id }
        author_info[:identities] = author.author_identities.map { |ai| { first_name: ai.first_name, middle_name: ai.middle_name, last_name: ai.last_name, email: ai.email, institution: ai.institution } }
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
  task :smci_export, [:input_file, :output_file, :date_since, :time_span] => :environment do |_t, args|
    output_file = args[:output_file]
    input_file = args[:input_file]
    date_since = args[:date_since]
    time_span = args[:time_span]
    smci = SMCIReport.new(input_file: input_file, output_file: output_file, date_since: date_since, time_span: time_span)
    smci.run
  end
end
