# frozen_string_literal: true

# Exports all publications for the given sunets or cap_profile_ids in an 'approved' state
#  and it also harvests publications by name for authors who do not have a sunet or cap_profile_id
# This is a custom report for Stanford Medicine Center for Improvement (SMCI)
#   specified in https://github.com/sul-dlss/sul_pub/issues/1201

# October 2020

# You must have an input csv file with the following columns (including a header row):
#   sunetid,cap_profile_id,first_name,middle_name,last_name,institutions,orcid,time_span
#
#  For authors that exist in profiles, you can specify either a sunet or cap_profile_id (sunet preferred if both specified)
#  For authors that do NOT exist in profiles, you MUST leave the cap_profile_id and sunet field columns blank, and then
#    you must specify first name and last name
#    and optionally middle name a comma delimited list of institutions (defaults to 'stanford' if no institutions provided)
#    Optionally, you can include an ORCID, which will take precedence over a name search for non-Profiles authors
#    Optionally, you can include a symbolicTimeSpan, which will override the default symbolicTimeSpan passed in (if any) for all non-Profiles author searches

# You can run it on the Rails console with:
#
# smci = SMCIReport.new(input_file: 'tmp/input.csv', output_file: 'tmp/output_file.csv', date_since: '1/1/2000', time_span: '1year')
# smci.run

# You can also run as a rake task to avoid having to drop into the rails console:

#
# bundle exec rake sul:smci_export['tmp/authors.csv','tmp/results.csv','1/1/2000','10year']
# bundle exec rake sul:smci_export['tmp/authors.csv','tmp/results.csv',,] # for all time

# Note that in either case, the runtime may take a while (like 30 mins or longer) if you have a reasonable large (>100) number of authors
#  so I'd suggest running in screen or nohup.

# The 'input_file' parameter indicates where your input CSV file with the desired authors is.
# The 'output_file' parameter species where the output CSV will be generated.

# The 'date_since' parameter is optional and specifies the date after which publications for profiles authors will be exported
#  The format for 'date_since'  is DD/MM/YYYY.

# The 'time_span' parameter is optional and specifies the WoS symbolic timespan lookup window for non-profiles authors
#   The allowed values for time_span are here: https://github.com/sul-dlss/sul_pub/wiki/Clarivate-APIs and are typically like '1year'

# If you leave 'date_since' or 'time_span' off or set to NIL, this means that the search is performed for all time
#  Note that you will most likely want them to match as much as possible for consistency across authors.

# Logging will be to 'log/smci_report.log'

# For many authors, this task may take many minutes, so it is recommended you run in screen or nohup.
#  There is no error/exception handling, so a crash mid-way (e.g. during WOS harvesting for some author)
#  will require a complete restart of the export.

# NOTE: This borrowed some code from the 'export_pubs_for_authors_csv' rake task in lib/tasks/sul.rake

require 'csv'

class SMCIReport
  # rubocop:disable Metrics/CyclomaticComplexity
  def initialize(args)
    @input_file = args[:input_file]
    @output_file = args[:output_file]
    @date_since = args[:date_since] || nil # the created_date to look back to for authors with profiles publications
    @time_span = args[:time_span] || nil # the symbolicTimeSpan parameter for WoS queries for authors NOT in profiles (e.g. 1year)
    # allowed values here: https://github.com/sul-dlss/sul_pub/wiki/Clarivate-APIs
    # in either case, NIL will fetch both types of publications for all time

    raise 'missing required params' unless @output_file && @input_file
    raise 'missing input csv' unless File.file? @input_file
    raise ArgumentError, 'supplied date_since is not valid' if @date_since && !Time.zone.parse(@date_since)
  end

  def logger
    @logger ||= Logger.new('log/smci_export.log')
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def run
    rows = CSV.parse(File.read(@input_file), headers: true)
    total_authors = rows.size
    total_pubs = 0
    start_time = Time.zone.now
    logger.info '*****************'
    logger.info 'Starting export.'
    logger.info "Exporting all publications for #{total_authors} authors to #{@output_file}. Since date: '#{@date_since}'.  " \
      "WoS SymbolicTimeSpan: '#{@time_span}'"
    logger.info ''

    CSV.open(@output_file, 'wb') do |csv|
      csv << header_row
      rows.each_with_index do |row, i| # loop over all authors in the input csv file
        logger.info "** Author #{i + 1} of #{total_authors}"
        sunet = row['sunetid']
        cap_profile_id = row['cap_profile_id']
        first_name = row['first_name']
        middle_name = row['middle_name']
        last_name = row['last_name']
        institutions = row['institutions']
        orcid = row['orcid']
        time_span = row['time_span']

        # check to see if we have either a sunet or cap_profile_id value for this row
        #  this would indicate this is an author in profiles
        if sunet || cap_profile_id

          # this is a profiles author, find them in the database
          if sunet
            author = Author.find_by(sunetid: sunet)
            logger.info "searching for author by sunet '#{sunet}'"
          elsif cap_profile_id
            author = Author.find_by(cap_profile_id: cap_profile_id)
            logger.info "searching for author by cap_profile_id '#{cap_profile_id}'"
          end
          # end check for either sunet or cap_profile_id

          if author # we found the author in our database, now get their publications
            contributions = Contribution.select('*')
            contributions = contributions.where(author: author).where(status: %w[new approved])
            contributions = contributions.where('created_at > ?', Time.zone.parse(@date_since)) if @date_since
            num_pubs_found = contributions.size
            logger.info "found #{author.first_name} #{author.last_name} with #{num_pubs_found} approved publications"
            total_pubs += num_pubs_found
            # loop over all of their approved publications and output the results
            contributions.each do |contribution|
              csv << output_row(pub_hash: contribution.publication.pub_hash, author: author,
                                harvested_at: contribution.created_at.to_s(:db), publication_status: contribution.status)
            end
          else # we could not find this author in the database
            logger.error 'author not found in database'
          end
          # end check if author exists

        else # this is NOT a profiles author, so we need to harvest this author directly from WoS using the name provided

          symbolicTimeSpan = time_span || @time_span
          if orcid.blank?
            # no orcid, search by name
            logger.info "harvesting author by name from WoS: '#{first_name} #{middle_name} #{last_name}', institutions: '#{institutions}'"
            # create a temporary author model object so we can generate the correct query
            author = Author.new(preferred_first_name: first_name, preferred_last_name: last_name,
                                preferred_middle_name: middle_name)
            # if institutions were provided in the row, add the author identities to our temporary author model object
            institutions&.split(',')&.each do |institution|
              author.author_identities << AuthorIdentity.new(first_name: first_name, last_name: last_name,
                                                             middle_name: middle_name, institution: institution.strip)
            end
            # end check for institutions for this author
            author_query = WebOfScience::QueryAuthor.new(author, symbolicTimeSpan: symbolicTimeSpan) # setup the WOS name query
            uids = author_query.uids # now fetch all of the WOS_UIDs for the publications for this author by running the name search
            logger.info(author_query.send(:author_query)) # log the name query being sent to WoS
          else
            # we have an orcid, search by orcid
            logger.info "harvesting author by orcid from WoS: '#{orcid}'"
            params = WebOfScience.queries.params_for_search("RID=(\"#{orcid.gsub('orcid.org/', '')}\")")
            if symbolicTimeSpan.present?
              params[:queryParameters][:symbolicTimeSpan] = symbolicTimeSpan
              params[:queryParameters].delete(:timeSpan)
              params[:queryParameters][:order!] = %i[databaseId userQuery symbolicTimeSpan queryLanguage] # according to WSDL
            end
            retriever = WebOfScience.queries.search(params)
            uids = retriever.merged_uids # now fetch all of the WOS_UIDs for the publications for this author by running the orcid search
          end
          num_pubs_returned = uids.size
          if num_pubs_returned < Settings.WOS.max_publications_per_author # verify that we don't have too many publications (usually caused by a bad name query)
            total_pubs += num_pubs_returned
            unless uids.empty? # check to see if there are any results
              results = WebOfScience.queries.retrieve_by_id(uids) # now fetch the publication details for these WOS_UIDs
              while results.next_batch? # as long as we have another page of results, retrieve them
                results.next_batch.to_a.each do |pub|
                  csv << output_row(pub_hash: pub.pub_hash, orcid: orcid)
                end
              end
            end
            # end check for any publications to fetch for this author
            logger.info "found #{num_pubs_returned} publications from WoS"
          else # too many publications were found for this author, do not export
            logger.error "too many publications found for this author in WoS - Pubs found: #{num_pubs_returned} > #{Settings.WOS.max_publications_per_author}"
          end
          # end check for too many publications for this author
        end
        # end check if this was a profiles author or not
      end
      # end loop over all authors in the CSV
    end
    # end writing the output CSV

    end_time = Time.zone.now
    logger.info ''
    logger.info "Total publications exported: #{total_pubs}. Output file: #{@output_file}. Total time: #{((end_time - start_time) / 60.0).round(1)} minutes."
    logger.info 'Completed export.'
    logger.info '*****************'
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  private

  def header_row
    %w[title author_list pmid wos_uid sul_pub_id doi doi_url publisher journal volume articlenumber supplement issue
       pages mesh pub_year pub_date provenance orcid profiles_author_last_name profiles_author_first_name
       profiles_author_sunet profiles_author_cap_profile_id profiles_author_employee_id profiles_author_email publication_status
       pub_harvested_date apa_citation mla_citation chicago_citation]
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def output_row(pub_hash:, harvested_at: Time.now.utc.to_s(:db), author: nil, orcid: nil, publication_status: 'unknown')
    author_list = if pub_hash[:author]
                    Csl::RoleMapper.send(:parse_authors, pub_hash[:author]).map do |a|
                      "#{a['family']}, #{a['given']}"
                    end.join('; ')
                  else
                    ''
                  end
    pmid = pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'pmid' }.compact.join
    doi = pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'doi' }.compact.join
    wos_uid = pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'wosuid' }.compact.join
    sul_pub_id = pub_hash[:identifier].map { |ident| ident[:id] if ident[:type].downcase == 'sulpubId' }.compact.join
    doi_url = pub_hash[:identifier].map { |ident| ident[:url] if ident[:type].downcase == 'doi' }.compact.join
    journal = pub_hash[:journal] ? pub_hash[:journal][:name] : ''
    issue = pub_hash[:journal] ? pub_hash[:journal][:issue] : ''
    volume = pub_hash[:journal] ? pub_hash[:journal][:volume] : ''
    article_number = pub_hash[:journal] ? pub_hash[:journal][:articlenumber] : ''
    mesh = if pub_hash[:mesh_headings]
             pub_hash[:mesh_headings].map do |h|
               h[:descriptor][0][:name]
             end.compact.reject(&:empty?).join('; ')
           else
             ''
           end
    if author # if this is a profiles author, then we will output this info as well
      author_last_name = author.last_name
      author_first_name = author.first_name
      author_sunet = author.sunetid
      author_cap_profile_id = author.cap_profile_id
      author_univ_id = author.university_id
      author_email = author.email
    else
      author_last_name = author_first_name = author_sunet = author_cap_profile_id = author_univ_id = author_email = ''
    end

    [pub_hash[:title],
     author_list,
     pmid,
     wos_uid,
     sul_pub_id,
     doi,
     doi_url,
     pub_hash[:publisher],
     journal,
     issue,
     volume,
     article_number,
     pub_hash[:supplement],
     pub_hash[:pages],
     mesh,
     pub_hash[:year],
     pub_hash[:date],
     pub_hash[:provenance],
     orcid,
     author_last_name,
     author_first_name,
     author_sunet,
     author_cap_profile_id,
     author_univ_id,
     author_email,
     publication_status,
     harvested_at,
     pub_hash[:apa_citation],
     pub_hash[:mla_citation],
     pub_hash[:chicago_citation]]
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
