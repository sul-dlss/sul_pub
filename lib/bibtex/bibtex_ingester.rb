# Note: there is no 'Bibtex' module in sul_pub to avoid any conflicts with other gems
require 'bibtex'
require 'citeproc'

class BibtexIngester
  def ingest_from_source_directory(directory)
    @batch_dir = directory || Settings.BIBTEX.IMPORT.DIR
    @bibtex_import_logger = Logger.new(Settings.BIBTEX.IMPORT.LOG)
    @bibtex_import_logger.info "Started bibtext import #{Time.zone.now}"
    @total_records_processed = 0
    @matches_on_issn_count = 0
    @matches_on_title_count = 0
    @total_duplicates = 0
    @total_faulty_record_count = 0
    @total_successfully_ingested = 0
    @missing_sunet_id_count = 0
    @records_without_sunet_id = 0
    @bad_file_error_count = 0
    @good_file_count = 0
    @total_deduped_count = 0
    @total_new_pubs = 0
    @batch_source_records_created_count = 0
    @unidentified_pub_type_count = 0
    skip_dirs = %w(. ..)
    Dir.open(@batch_dir).each do |batch_dir_name|
      next if skip_dirs.include? batch_dir_name
      batch_dir_full_path = "#{@batch_dir}/#{batch_dir_name}"
      next unless File.directory? batch_dir_full_path
      Dir.open(batch_dir_full_path).each do |bibtex_file_name|
        # sunet_id = File.basename(bibtex_file_name, '.*')
        next if skip_dirs.include? batch_dir_name

        file_full_path = "#{batch_dir_full_path}/#{bibtex_file_name}"
        log_file_full_path = "#{batch_dir_full_path}/#{bibtex_file_name}_import.log"
        next if File.directory?(file_full_path) || bibtex_file_name == '.DS_Store' || bibtex_file_name.end_with?('.log')
        @record_count_for_file = 0
        @errors_for_file = 0
        @ingested_for_file = 0

        @bibtex_file_logger = Logger.new(log_file_full_path)
        @bibtex_file_logger.info "Started bibtext import for file #{Time.zone.now}"

        process_bibtex_file(file_full_path, batch_dir_name, bibtex_file_name)

        @bibtex_file_logger.info "Ended bibtext import for file #{Time.zone.now}"
        @bibtex_file_logger.info "#{@record_count_for_file} records processed."
        @bibtex_file_logger.info "#{@ingested_for_file} records were successfully ingested."
        @bibtex_file_logger.info "#{@errors_for_file} records had problems and weren't ingested."
      end
    end
    @bibtex_import_logger.info "Finished bibtex import #{Time.zone.now}"
    @bibtex_import_logger.info "#{@bad_file_error_count} files couldn't be parsed at all."
    @bibtex_import_logger.info "#{@good_file_count} files were parsed."
    @bibtex_import_logger.info "#{@missing_sunet_id_count} files containing #{@records_without_sunet_id} records weren't parsed because the sunet id wasn't found in the db."

    @bibtex_import_logger.info "#{@total_records_processed} records processed for import."
    @bibtex_import_logger.info "#{@total_successfully_ingested} records were ingested or were duplicates."
    @bibtex_import_logger.info "#{@total_faulty_record_count} records weren't ingested or weren't duplicates."
    @bibtex_import_logger.info "#{@unidentified_pub_type_count} records weren't ingested because their pub type wasn't identified."

    @bibtex_import_logger.info "#{@batch_source_records_created_count} batch_source_records were created."
    @bibtex_import_logger.info "#{@total_duplicates} were duplicates from prior batch."

    @bibtex_import_logger.info "#{@matches_on_issn_count} matched existing sw or pubmed pubs by issn."
    @bibtex_import_logger.info "#{@matches_on_title_count} matched existing existing sw or pubmed pubs by title."
    @bibtex_import_logger.info "#{@total_deduped_count} total records were deduplicated against sw or pubmed pubs."
    @bibtex_import_logger.info "#{@total_new_pubs} new publication records were created."
  end

  def process_bibtex_file(file_full_path, _batch_name, bibtex_file_name)
    sunet_id = File.basename(bibtex_file_name, '.*')

    author = Author.where(sunetid: sunet_id).first
    if author.nil?
      @missing_sunet_id_count += 1
      @bibtex_import_logger.info "Couldn't find an author for sunetid: #{sunet_id}"
      @bibtex_file_logger.info "Couldn't find an author for sunetid: #{sunet_id}"
      begin
        @records_without_sunet_id += BibTeX.open(file_full_path).count
      rescue => e
        @bad_file_error_count += 1
        @bibtex_import_logger.error "Couldn't open the bibtex file anyhow, #{bibtex_file_name}, at all: "
        @bibtex_import_logger.error e.message
        @bibtex_file_logger.error e.message
        @bibtex_file_logger.error e.backtrace
      end
    else
      begin
        records = BibTeX.open(file_full_path)
      rescue => e
        @bibtex_import_logger.error "Couldn't open the bibtex file, #{bibtex_file_name}, at all: "
        @bibtex_import_logger.error "See the log file for #{sunet_id} for details."
        @bibtex_import_logger.error e.message
        @bibtex_file_logger.error "Couldn't open the bibtex file at all: "
        @bibtex_file_logger.error e.message
        @bibtex_file_logger.error e.backtrace
        @bad_file_error_count += 1
      end
      if records.present?
        @good_file_count += 1
        records.each do |record|
          @record_count_for_file += 1
          @total_records_processed += 1
          process_record(record, author)
        end
      else
        @bibtex_import_logger.error "no records for file: #{bibtex_file_name}"
      end
    end
  end

  def process_record(record, author)
    begin
      existing_source_record = BatchUploadedSourceRecord.where(sunet_id: author.sunetid, title: record.title.to_s).first
    rescue => e
      @bibtex_import_logger.info "Search for existing batch upload for : #{record} failed probably because of unicode issue."
      @bibtex_import_logger.info "Error: #{e.message}"
    end

    source_attrib_hash = {
      is_active: true,
      sunet_id: author.sunetid,
      successful_import: true,
      bibtex_source_data: record.to_s
    }
    source_attrib_hash[:title] = record.title.to_s if record['title'].present?
    source_attrib_hash[:year] = record.year.to_s if record['year'].present?

    bibtex_mapper = BibtexMapper.new(record)

    if existing_source_record
      pub = existing_source_record.publication
      @total_duplicates += 1
      # if the publication has been updated with a sw or pubmed record since it was first submitted, then do nothing
      if pub.sciencewire_id.blank? && pub.pmid.blank?
        pub.update_attributes(active: true, pub_hash: bibtex_pub_hash(bibtex_mapper, author))
        existing_source_record.update_attributes(source_attrib_hash)
        existing_source_record.save
      end
    elsif bibtex_mapper.sul_document_type.present?
      pub = find_existing_pub(record)
      if pub.nil?
        pub = Publication.create(active: true, pub_hash: bibtex_pub_hash(bibtex_mapper, author))
        @total_new_pubs += 1
      end
      BatchUploadedSourceRecord.create(publication_id: pub.id).update_attributes(source_attrib_hash)
      @batch_source_records_created_count += 1
      # create the contribution regardless of whether we created a new pub or are using an existing pub
      Contribution.where(
        author_id: author.id,
        publication_id: pub.id
      )
                  .first_or_create(
                    cap_profile_id: author.cap_profile_id,
                    status: 'approved',
                    visibility: 'private',
                    featured: false
                  )
      # have to sync the pub hash to update new information, including new authorship
      pub.sync_publication_hash_and_db
      pub.save
    else
      @unidentified_pub_type_count += 1
      @bibtex_import_logger.info "No pub type for: #{record}"
    end
    @ingested_for_file += 1
    @total_successfully_ingested += 1
  rescue StandardError => e
    @bibtex_import_logger.error "Record not ingested: #{record}"
    @bibtex_import_logger.error "Error: #{e.message}"
    @bibtex_import_logger.error e.backtrace.join("\n") if e.backtrace.present?
    @total_faulty_record_count += 1
  end

  def find_existing_pub(record)
    pub = nil
    issn = record['issn'].to_s || record['ISSN'].to_s
    pages = record['pages'].to_s
    year = record['year'].to_s
    title = record['title'].to_s

    if issn.present? && pages.present? && year.present?
      begin
        pub = Publication.where("(sciencewire_id is not null OR pmid is not null)
              AND issn =? AND pages=? AND year=? ", issn, pages, year).first
      rescue => e
        @bibtex_import_logger.info "Search for existing sw or pubmed pub for : #{record} failed probably because of unicode issue."
        @bibtex_import_logger.info "Error: #{e.message}"
      end
      @matches_on_issn_count += 1 if pub
    end
    if pub.nil? && title.present? && pages.present? && year.present?
      begin
        pub = Publication.where("(sciencewire_id is not null OR pmid is not null)
              AND title= ? AND year= ? AND pages= ? ", title, year, pages).first
      rescue => e
        @bibtex_import_logger.info "Search for existing sw or pubmed pub for : #{record} failed probably because of unicode issue."
        @bibtex_import_logger.info "Error: #{e.message}"
      end

      @matches_on_title_count += 1 if pub
    end
    @total_deduped_count += 1 if pub
    pub
  end

  private

    # @param [Author] author
    # @return [Array<Hash>]
    def bibtex_authorship(author)
      authorship_hash = {
        sul_author_id: author.id,
        status: 'approved',
        visibility: 'public',
        featured: false
      }
      authorship_hash[:cap_profile_id] = author.cap_profile_id if author.cap_profile_id.present?
      [authorship_hash]
    end

    # @param [BibtexMapper] bibtex_mapper
    # @param [Author] author
    # @return [Hash]
    def bibtex_pub_hash(bibtex_mapper, author)
      bibtex_mapper.pub_hash.merge(authorship: bibtex_authorship(author))
    end

end
