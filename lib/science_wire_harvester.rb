require 'dotiw'
require 'parallel'

class ScienceWireHarvester
  include ActionView::Helpers::DateHelper
  # harvest sciencewire records for all authors using author information
  # expose the sciencewire client for rspec testing
  attr_reader :sciencewire_client
  attr_reader :records_queued_for_pubmed_retrieval
  attr_reader :records_queued_for_sciencewire_retrieval
  attr_reader :file_count

  attr_accessor :debug,
                :use_middle_name,
                :use_author_identities,
                :default_institution

  def initialize
    initialize_instance_vars
    initialize_counts_for_reporting
    @reject_types = Settings.sw_doc_types_to_skip.join('|')
  end

  def harvest_pubs_for_authors(authors)
    authors.find_each do |author|
      begin
        @harvested_for_author_count = 0
        @author_count += 1
        if @author_count % 50 == 0
          msg = "up to author id: #{author.id} with #{@total_suggested_count} total suggestions so far for #{@author_count} authors - #{Time.zone.now}"
          sw_harvest_logger.info msg
        end
        harvest_for_author(author)
      rescue => e
        msg = "Error for #{author.official_last_name} - sul author id: #{author.id} "
        sw_harvest_logger.error "#{msg}-  #{e.inspect}"
        sw_harvest_logger.error e.backtrace.join "\n"
        # NotificationManager.handle_harvest_problem(e, msg)
      end
    end
    process_queued_sciencewire_suggestions
    process_queued_pubmed_records
    write_counts_to_log
  end

  def harvest_pubs_for_author_ids(author_ids)
    # override the default initialization of the @sw_harvest_logger
    @sw_harvest_logger = Logger.new(Settings.SCIENCEWIRE.NIGHTLY_HARVEST_LOG)
    sw_harvest_logger.info "Started nightly authorship harvest #{Time.zone.now}"
    harvest_pubs_for_authors Author.where(id: author_ids)
  rescue => e
    NotificationManager.handle_harvest_problem(e, 'Error for with nightly harvest.')
  end

  def harvest_pubs_for_all_authors(starting_author_id, ending_author_id = -1)
    # override the default initialization of the @sw_harvest_logger
    @sw_harvest_logger = Logger.new(Settings.SCIENCEWIRE.HARVEST_LOG)
    sw_harvest_logger.info "Started full authorship harvest #{Time.zone.now}"
    authors = Author.where(active_in_cap: true, cap_import_enabled: true)
    authors = authors.where(Author.arel_table[Author.primary_key].gteq(starting_author_id))
    authors = authors.where(Author.arel_table[Author.primary_key].lteq(ending_author_id)) if ending_author_id > 0
    harvest_pubs_for_authors authors
  end

  def harvest_pubs_for_all_authors_parallel
    last_id = Author.last.id

    batch_count = 4
    batch_size = (last_id / batch_count).to_i
    batch_1 = [] << 1 << batch_size
    batch_2 = [] << (batch_size + 1) << (2 * batch_size)
    batch_3 = [] << (2 * batch_size + 1) << (3 * batch_size)
    batch_4 = [] << (3 * batch_size + 1) << last_id
    sacks = [] << batch_1 << batch_2 << batch_3 << batch_4
    Parallel.each(sacks, in_processes: 4) do |sack|
      # override the default initialization of the @sw_harvest_logger
      @sw_harvest_logger = Logger.new(Settings.SCIENCEWIRE.HARVEST_PID_LOG % Process.pid)
      @sw_harvest_logger.formatter = proc { |severity, datetime, _progname, msg|
        "#{severity} #{datetime}[#{Process.pid}]: #{msg}\n"
      }
      sw_harvest_logger.info 'Started search'

      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.logger.level = 1

      start_key = sack[0]
      stop_key = sack[1]
      authors = Author.where(active_in_cap: true, cap_import_enabled: true)
                .where(Author.arel_table[Author.primary_key].gteq(start_key))
                .where(Author.arel_table[Author.primary_key].lteq(stop_key))
      harvest_pubs_for_authors authors
    end
  end

  def initialize_instance_vars
    @sciencewire_client = ScienceWireClient.new
    @pubmed_client = PubmedClient.new
    # our two queues for sciencewire and pubmed calls
    @records_queued_for_sciencewire_retrieval = {}
    @records_queued_for_pubmed_retrieval = {}
    @use_middle_name = Settings.HARVESTER.USE_MIDDLE_NAME
    @use_author_identities = Settings.HARVESTER.USE_AUTHOR_IDENTITIES
    @default_institution = ScienceWire::AuthorInstitution.new(
      Settings.HARVESTER.INSTITUTION.name,
      ScienceWire::AuthorAddress.new(Settings.HARVESTER.INSTITUTION.address.to_hash)
    )
  end

  def initialize_counts_for_reporting
    @start_time = Time.zone.now
    # some counts for reporting
    @total_suggested_count = 0
    @new_pubs_created_count = 0
    @author_count = 0
    @contributions_created_count = 0
    @existing_contributions_count = 0
    @authors_with_no_seed_data_count = 0
    @total_new_pubmed_source_count = 0
    @total_new_sciencewire_source_count = 0
    @suggestions_with_pubmed_ids_count = 0
    @matches_on_existing_swid_count = 0
    @matches_on_existing_pmid_count = 0
    @matches_on_issn_count = 0
    @matches_on_title_count = 0
    @debug = false
  end

  def write_counts_to_log
    sw_harvest_logger.info "Finished harvest at #{Time.zone.now}"
    log_counts
  end

  def log_counts
    sw_harvest_logger.info "#{@total_suggested_count} total records were suggested for #{@author_count} authors."
    sw_harvest_logger.info "#{@existing_contributions_count} existing contributions were found."
    sw_harvest_logger.info "#{@contributions_created_count} new contributions were created."
    sw_harvest_logger.info "#{@total_new_pubmed_source_count} new pubmed source records were created."
    sw_harvest_logger.info "#{@total_new_sciencewire_source_count} new sciencewire source records were created."
    sw_harvest_logger.info "#{@new_pubs_created_count} new publications were created."
    sw_harvest_logger.info "#{@authors_with_no_seed_data_count} authors had no seed data and used the name search instead."
    sw_harvest_logger.info "#{@matches_on_existing_swid_count} existing publications were found by sciencewire id."
    sw_harvest_logger.info "#{@matches_on_existing_pmid_count} existing publications were deduped by pmid."
    sw_harvest_logger.info "#{@matches_on_issn_count} existing publications were deduped by issn."
    sw_harvest_logger.info "#{@matches_on_title_count} existing publications were deduped by title."
  end

  def increment_authors_with_limited_seed_data_count
    @authors_with_no_seed_data_count += 1
  end

  def harvest_for_author(author)
    sciencewire_ids = ScienceWire::HarvestBroker.new(author, self, alternate_name_query: use_author_identities).generate_ids
    sciencewire_ids.each do |sw_id|
      @total_suggested_count += 1
      was_record_created = create_contrib_for_pub_if_exists(sw_id, author)
      unless was_record_created
        # queue up sciencewire id, along with any associated authors,
        # for batched retrieval and processing
        @records_queued_for_sciencewire_retrieval[sw_id] ||= []
        @records_queued_for_sciencewire_retrieval[sw_id] << author.id
      end
      if @records_queued_for_sciencewire_retrieval.length > 100
        process_queued_sciencewire_suggestions
      end
      if @records_queued_for_pubmed_retrieval.length > 4000
        process_queued_pubmed_records
      end
      GC.start if @total_suggested_count % 1000 == 0
      if @debug
        log_counts
        @debug = false
      end
    end
  end

  def create_contribs_for_author_ids_and_pub(author_ids, pub)
    author_ids.each do |author_id|
      add_contribution_for_harvest_suggestion(Author.find(author_id), pub)
    end
  end

  def create_contrib_for_pub_if_exists_by_author_ids(sciencewire_id, author_ids)
    existing_pub = Publication.where(sciencewire_id: sciencewire_id).first
    if existing_pub
      create_contribs_for_author_ids_and_pub(author_ids, existing_pub)
      # TODO: see if we can add a before_save hook to contribution to update the parent pub_hash
      existing_pub.rebuild_authorship
      existing_pub.save
      @matches_on_existing_swid_count += 1
      true
    else
      false
    end
  end

  def create_contrib_for_pub_if_exists(sciencewire_id, author)
    existing_pub = Publication.where(sciencewire_id: sciencewire_id).first
    if existing_pub
      add_contribution_for_harvest_suggestion(author, existing_pub)
      @matches_on_existing_swid_count += 1
      true
    else
      false
    end
  end

  def add_contribution_for_harvest_suggestion(author, publication)
    contrib = Contribution.where(
      publication_id: publication.id,
      author_id: author.id).first
    if contrib
      # Existing contrib, do not modify the publication
      @existing_contributions_count += 1
    else
      Contribution.create(
        publication_id: publication.id,
        author_id: author.id,
        cap_profile_id: author.cap_profile_id,
        status: 'new',
        visibility: 'private',
        featured: false)
      @contributions_created_count += 1
      publication.rebuild_authorship
      publication.save
    end
  end

  # TODO: have AggregateText results use this directly instead of pulling out IDs
  def process_queued_sciencewire_suggestions
    list_of_sw_ids = @records_queued_for_sciencewire_retrieval.keys.join(',')
    sw_records_doc = @sciencewire_client.get_full_sciencewire_pubs_for_sciencewire_ids(list_of_sw_ids)
    sw_records_doc.xpath("//PublicationItem[regex_reject(DocumentTypeList, '#{@reject_types}')]", XpathUtils.new).each do |sw_doc|
      sciencewire_id = sw_doc.xpath('PublicationItemID').text
      pmid = sw_doc.xpath('PMID').text
      source_record_was_created = SciencewireSourceRecord.save_sw_source_record(sciencewire_id, pmid, sw_doc.to_xml)
      @total_new_sciencewire_source_count += 1 if source_record_was_created
      create_or_update_pub_and_contribution_with_harvested_sw_doc(sw_doc, @records_queued_for_sciencewire_retrieval[sciencewire_id.to_i])
    end
    @records_queued_for_sciencewire_retrieval.clear
  end

  def create_or_update_pub_and_contribution_with_harvested_sw_doc(incoming_sw_xml_doc, author_ids)
    pub_hash = SciencewireSourceRecord.convert_sw_publication_doc_to_hash(incoming_sw_xml_doc)
    pmid = pub_hash[:pmid]
    sciencewire_id = pub_hash[:sw_id]

    title = pub_hash[:title]
    year = pub_hash[:year]
    issn = pub_hash[:issn]
    pages = pub_hash[:pages]

    # disambig rules:
    # 1.check for existing pub by sw_id, pmid
    # 2.Look for ISSN. If matches, need to also check for year and first page.
    # 3.Look for Title, year, starting page

    # although we've already checked earlier, check again for an existing pub
    # with this scienciewire id in case one got created for some other reason
    was_record_already_created = create_contrib_for_pub_if_exists_by_author_ids(sciencewire_id, author_ids)
    return if was_record_already_created

    # nope, now check for an existing pub by pmid or issn/pages or title/year/pages
    if pmid.blank?
      pub = Publication.where(issn: issn, pages: pages, year: year).first unless issn.blank? || pages.blank?
      pub ||= Publication.where(title: title, year: year, pages: pages).first

      @matches_on_title_count += 1 if pub
      # if still no pub then create a new pub
      pub ||= create_new_harvested_pub(sciencewire_id, pmid)
    else
      Rails.logger.info "should find pmid here: #{pmid}"
      pub = Publication.where(pmid: pmid).first
      if pub
        @matches_on_existing_pmid_count += 1
      else
        # we don't have an existing sul pub for this pmid so queue this up for batch processing,
        # storing the pmid, author.id, and sw_hash.
        @records_queued_for_pubmed_retrieval[pmid] ||= {}
        @records_queued_for_pubmed_retrieval[pmid][:sw_hash] = pub_hash
        @records_queued_for_pubmed_retrieval[pmid][:authors] = author_ids
        return
      end
    end

    create_contribs_for_author_ids_and_pub(author_ids, pub)
    pub.build_from_sciencewire_hash(pub_hash)
    pub.sync_publication_hash_and_db
    pub.save
  end

  def create_new_harvested_pub(sciencewire_id, pmid)
    @new_pubs_created_count += 1
    Publication.create(
      active: true,
      sciencewire_id: sciencewire_id,
      pmid: pmid)
  end

  def process_queued_pubmed_records
    begin
      pubmed_source_record = PubmedSourceRecord.new
      pub_med_records = @pubmed_client.fetch_records_for_pmid_list(@records_queued_for_pubmed_retrieval.keys)
      Nokogiri::XML(pub_med_records).xpath('//PubmedArticle').each do |pub_doc|
        pmid = pub_doc.xpath('MedlineCitation/PMID').text
        pubmed_source_record = PubmedSourceRecord.create_pubmed_source_record(pmid, pub_doc)
        @total_new_pubmed_source_count += 1 if pubmed_source_record
        pub_hash = @records_queued_for_pubmed_retrieval[pmid][:sw_hash]
        author_ids = @records_queued_for_pubmed_retrieval[pmid][:authors]
        pub = create_new_harvested_pub(pub_hash[:sw_id], pmid)
        abstract = pubmed_source_record.extract_abstract_from_pubmed_record(pub_doc)
        mesh = pubmed_source_record.extract_mesh_headings_from_pubmed_record(pub_doc)

        pub_hash[:mesh_headings] = mesh unless mesh.blank?
        pub_hash[:abstract] = abstract unless abstract.blank?

        create_contribs_for_author_ids_and_pub(author_ids, pub)
        pub.pub_hash = pub_hash
        pub.sync_publication_hash_and_db
        pub.save
      end
    rescue => e
      NotificationManager.handle_harvest_problem(e, 'The batch call to pubmed, process_queued_pubmed_records, failed.')
    end
    @records_queued_for_pubmed_retrieval.clear
  end

  def harvest_from_directory_of_wos_id_files(path_to_directory)
    sw_harvest_logger.info "Started Web Of Science harvest #{Time.zone.now}"
    @wos_ids_processed = 0
    @file_count = 0
    Dir.glob(path_to_directory.to_s + '/*').each do |f|
      begin
        sunetid = f.split('/').last
        sw_harvest_logger.info "Processing #{sunetid}"
        wos_ids = process_bibtex_file(f)
        if wos_ids.empty?
          sw_harvest_logger.warn "No ids to process for #{sunetid}. Skipping"
          next
        end
        harvest_sw_pubs_by_wos_id_for_author(sunetid, wos_ids)
        @file_count += 1
      rescue => e
        sw_harvest_logger.error "Problem with #{f}"
        sw_harvest_logger.error e.inspect << "\n" << e.backtrace.join("\n")
      end
    end
    sw_harvest_logger.info "#{@file_count} files processed"
    sw_harvest_logger.info "#{@wos_ids_processed} Web Of Science IDs parsed"
    write_counts_to_log
  end

  def process_bibtex_file(path_to_file)
    mode = nil
    ids = []
    IO.readlines(path_to_file).each do |l|
      if l =~ /^@inproceedings/
        mode = :inproceedings
        next
      end
      if l =~ /^Unique-ID.*ISI:(.*)}},/
        if (mode == :inproceedings)
          @wos_ids_processed += 1
          ids << Regexp.last_match(1)
        end
        mode = nil
      end
    end
    ids
  end

  # @param [String] sunetid identifier for the author
  # @param [Array<String>] wos_ids WebOfScienceID Document IDs to pull
  def harvest_sw_pubs_by_wos_id_for_author(sunetid, wos_ids)
    author = Author.where(sunetid: sunetid).first
    fail("Author with sunetid #{sunetid} does not exist") if author.nil?

    all_sw_docs = @sciencewire_client.get_full_sciencewire_pubs_for_wos_ids(wos_ids)

    # TODO: refactor our similar processing from suggestions/name search
    all_sw_docs.xpath('//PublicationItem').each do |sw_doc|
      begin
        sciencewire_id = sw_doc.at_xpath('PublicationItemID').text
        record_created = create_contrib_for_pub_if_exists(sciencewire_id, author)
        unless record_created
          pmid = sw_doc.xpath('PMID').text
          source_record_was_created = SciencewireSourceRecord.save_sw_source_record(sciencewire_id, pmid, sw_doc.to_xml)
          @total_new_sciencewire_source_count += 1 if source_record_was_created
          create_or_update_pub_and_contribution_with_harvested_sw_doc(sw_doc, [author.id])
        end
        if @debug
          sw_harvest_logger.info "#{@file_count} files processed"
          sw_harvest_logger.info "#{@wos_ids_processed} Web Of Science Ids processed"
          log_counts
          @debug = false
        end
      rescue => e
        sw_harvest_logger.error "Unable to process #{sciencewire_id}"
        sw_harvest_logger.error e.inspect << "\n" << e.backtrace.join("\n")
      end
    end

    process_queued_pubmed_records
  end

  def harvest_sw_pubs_by_wos_array_and_sunetid(sunetid, wos_ids, batch_size = 20)
    batches = wos_ids.size / batch_size
    (0..batches).each do |batch_num|
      starting_index = batch_num * batch_size
      sw_harvest_logger.info "Starting next batch at #{starting_index}"
      wos_batch = wos_ids[starting_index, batch_size]
      harvest_sw_pubs_by_wos_id_for_author sunetid, wos_batch
    end
    log_counts
    process_queued_pubmed_records
  end

  # Used for targeted harvesting for an author by sunetid and a json-file with an array of WOS id
  # Instantiates the logger too
  def harvest_for_sunetid_with_wos_json(sunetid, path_to_json, batch_size = 20)
    sw_harvest_logger.info "Started Web Of Science harvest for #{sunetid} with wos-json #{path_to_json}"

    wos_ids = JSON.parse IO.read path_to_json
    harvest_sw_pubs_by_wos_array_and_sunetid sunetid, wos_ids, batch_size
  end

  # Process a text file with lines that have this format of WOS document id and cap profile id:
  #  WOS:000314860700023	38808
  def harvest_from_wos_id_cap_profile_id_report(path_to_report)
    lines = IO.readlines path_to_report

    _, batch_profile_id = parse_wos_line(lines.first)
    wos_ids = []
    lines.each do |line|
      next if line.empty?

      begin
        wos_id, current_profile_id  = parse_wos_line(line)

        # process the last batch of WOS ids
        if current_profile_id != batch_profile_id
          begin
            process_wos_ids_for_author(batch_profile_id, wos_ids)
          ensure
            wos_ids = []
            batch_profile_id = current_profile_id
          end
        end
        wos_ids << wos_id

      rescue => e
        sw_harvest_logger.error "Unable to process line: #{line}"
        sw_harvest_logger.error e.inspect << "\n" << e.backtrace.join("\n")
      end
    end

    # handle last set of WOS ids
    process_wos_ids_for_author(batch_profile_id, wos_ids)
  end

  # @param [String] line A string with the format "WOS:000314860700023	38808"
  # @return [Array<String>] first element wos_id. second_element cap_profile_id
  def parse_wos_line(line)
    line =~ /WOS:([^\s]*)\s+(\d+)/
    [Regexp.last_match(1), Regexp.last_match(2)]
  end

  def process_wos_ids_for_author(cap_profile_id, wos_ids)
    sunetid = Author.where(cap_profile_id: cap_profile_id).pluck(:sunetid).first
    if sunetid.nil?
      sw_harvest_logger.error "No sunetid found for cap_profile_id: #{cap_profile_id}. Skipping"
    else
      sw_harvest_logger.info "Starting harvest for sunetid: #{sunetid} cap_profile_id: #{cap_profile_id} with #{wos_ids.size} WOS ids"
      harvest_sw_pubs_by_wos_array_and_sunetid sunetid, wos_ids
    end
  end

  private

    def sw_harvest_logger
      @sw_harvest_logger ||= begin
        logger = Logger.new(Settings.SCIENCEWIRE.WOS_HARVEST_LOG)
        logger.datetime_format = '%Y-%m-%d %H:%M:%S'
        logger.formatter = proc { |severity, datetime, _progname, msg|
          "#{severity} #{datetime}: #{msg}\n"
        }
        logger
      end
    end
end
