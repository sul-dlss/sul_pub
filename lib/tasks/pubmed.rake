namespace :pubmed do
  def client
    @client ||= Pubmed.client
  end

  desc 'update pubmed source records and rebuild pub_hashes for publications for a given list of cap_profile_ids passed in a text file'
  # filename should be a list of cap_profile_id, one per line with no header
  # call with RAILS_ENV=production bundle exec rake pubmed:update_pubmed_source_records_for_cap_profile_ids['filename.txt']
  task :update_pubmed_source_records_for_cap_profile_ids, [:filename] => :environment do |_t, args|
    filename = args[:filename]
    raise "filename is required." unless filename.present?

    cap_profile_ids = File.readlines(filename)
    logger = Logger.new(Rails.root.join('log', 'update_pubmed_source_records_for_cap_profile_ids.log'))
    include ActionView::Helpers::DateHelper
    $stdout.sync = true # flush output immediately
    total_authors = cap_profile_ids.size
    error_count = 0
    authors_found = 0
    authors_not_found = 0
    pubs_updated_count = 0
    total_pubs = 0
    start_time = Time.zone.now
    max_errors = 10
    message = "Started at #{start_time}.  Working on #{total_authors} authors."
    puts message
    logger.info message
    cap_profile_ids.each_with_index do |cap_profile_id, index|
      id = cap_profile_id.chomp
      current_time = Time.zone.now
      elapsed_time = current_time - start_time
      avg_time_per_author = elapsed_time / (index + 1)
      total_time_remaining = (avg_time_per_author * (total_authors - index)).floor
      message = "...#{current_time}: on cap_profile_id #{id} : #{index + 1} of #{total_authors} : ~ #{distance_of_time_in_words(start_time, start_time + total_time_remaining.seconds)} left"
      puts message
      logger.info message
      author = Author.find_by_cap_profile_id(id)
      if author.blank?
        authors_not_found += 1
        message = "*****cap_profile_id #{id} not found"
        puts message
        logger.error message
      else
        pubs = author.publications.where("pmid is not null OR pmid !=''")
        message = ".....#{author.first_name} #{author.last_name} has #{pubs.size} publications with a PMID"
        puts message
        logger.info message
        total_pubs += pubs.count
        pubs.each do |pub|
          begin
            result = pub.update_from_pubmed
            pubs_updated_count += 1 if result
          rescue => e
            message = "*****ERROR on cap_profile_id #{id} for publication_id #{pub.id}: #{e.message}"
            puts message
            logger.error message
            error_count += 1
          end
        end
        authors_found += 1
      end
      next unless error_count > max_errors

      message = "Halting: Maximum number of errors #{max_errors} reached"
      logger.error message
      raise message
    end
    end_time = Time.zone.now
    message = "Total: #{total_authors}. Authors found: #{authors_found}. Authors not found: #{authors_not_found}.  Total publications: #{total_pubs}.  Publications updated: #{pubs_updated_count}.  Errored publications: #{error_count}.  Ended at #{end_time}.  Total time: #{distance_of_time_in_words(end_time, start_time)}"
    puts message
    logger.info message
  end

  desc 'Retrieve and print a single publication by PubMed-ID'
  task :publication, [:pmid] => :environment do |_t, args|
    raise "pmid argument is required." unless args[:pmid].present?

    pmids = [args[:pmid]]
    doc = client.fetch_records_for_pmid_list(pmids)
    puts doc # XML document
  end

  # desc 'Harvest using a plain text file with a list of publications by PubmedID (no header row) for the supplied cap_profile_id'
  # # file format is a plain text file, no header row, one line per PubmedID
  # task :pmid_profile_id_import, [:path_to_report, :cap_profile_id] => :environment do |_t, args|
  #   author = Author.find_by_cap_profile_id(args[:cap_profile_id])
  #   abort "cap_profile_id #{args[:cap_profile_id]} not found" if author.nil?
  #
  #   abort "#{args[:path_to_report]} not found" unless File.file?(args[:path_to_report])
  #   lines = IO.readlines args[:path_to_report]
  #
  #   puts "Cap_profile_id #{args[:cap_profile_id]} is #{author.first_name} #{author.last_name}"
  #   total_pub_count = author.contributions.size
  #   new_pub_count = author.contributions.where(status: 'new').size
  #   approved_pub_count = author.contributions.where(status: 'approved').size
  #   puts "total publications: #{total_pub_count}"
  #   puts "total new publications: #{new_pub_count}"
  #   puts "total accepted publications: #{approved_pub_count}"
  #   puts "attempting to harvest #{lines.count} new publications by pubmedID"
  #   puts
  #
  #   failed = 0
  #   success = 0
  #   harvester = ScienceWireHarvester.new
  #   lines.each do |line|
  #     pmid = line.chomp
  #     puts "working on #{pmid}..."
  #     begin
  #       pub = Publication.find_or_create_by_pmid(pmid)
  #       harvester.add_contribution_for_harvest_suggestion(author, pub)
  #       pub.add_all_db_contributions_to_my_pub_hash
  #       pub.save
  #       success += 1
  #     rescue => e
  #       failed += 1
  #       puts "**** error: #{e.message}"
  #     end
  #   end
  #
  #   author.reload
  #   new_pub_count = author.contributions.where(status: 'new').size - new_pub_count
  #   puts ""
  #   puts "total new publications added: #{new_pub_count}"
  #   puts "success: #{success}"
  #   puts "errors: #{failed}"
  # end

  desc 'Harvest from Pubmed, for all authors, for all time'
  task harvest_authors: :environment do
    Pubmed.harvester.harvest_all
  end

  # See https://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ESearch for explanation of dates
  desc 'Update harvest from Pubmed, for all authors'
  task :harvest_authors_update, [:reldate] => :environment do |_t, args|
    options = args.with_defaults(reldate: Settings.PUBMED.regular_harvest_timeframe)
    Pubmed.harvester.harvest_all(options)
  end

  desc 'Harvest from Pubmed, for one author'
  task :harvest_author, [:cap_profile_id, :reldate] => :environment do |_t, args|
    author = Author.find_by(cap_profile_id: args[:cap_profile_id])
    raise "Could not find Author by cap_profile_id: #{args[:cap_profile_id]}." if author.nil?

    options = {}
    options[:reldate] = args[:reldate] if args[:reldate].present?
    Pubmed.harvester.process_author(author, options)
  end
end
