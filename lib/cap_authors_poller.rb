require 'dotiw'
require 'time'
class CapAuthorsPoller
  include ActionView::Helpers::DateHelper

  attr_reader :logger

  def initialize
    @sw_harvester = ScienceWireHarvester.new
    @cap_http_client = CapHttpClient.new
    @logger = Logger.new(Settings.CAP.AUTHORS_POLL_LOG)
    @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    @logger.formatter = proc { |severity, datetime, _progname, msg|
      "#{severity} #{datetime}: #{msg}\n"
    }
    init_stats
  end

  def debug=(val)
    log_stats
    @sw_harvester.debug = val
  end

  def get_authorship_data(days_ago = 1)
    logger.info "Started CAP authorship import - #{Time.zone.now}"
    @new_or_changed_authors_to_harvest_queue = []
    page_count = 0
    page_size = 1000
    loop do
      begin
        page_count += 1
        json_response = get_recent_cap_authorship(page_count, page_size, days_ago)
        process_next_batch_of_authorship_data(json_response)
        logger.info "#{@total_running_count} records were processed in #{log_process_time}"
        break if json_response['lastPage']
      rescue => e
        logger.fail e.inspect
        raise
      end
    end

    log_stats
    do_science_wire_harvest

    info = []
    info << "#{page_count} pages with #{page_size} records were processed in #{log_process_time}"
    info << "#{@new_author_count} authors were created."
    info << 'Finished authorship import'
    logger.info info.join("\n")
  rescue => e
    msg = "Authorship import failed - #{Time.zone.now}"
    NotificationManager.handle_authorship_pull_error(e, msg)
  end

  def cap_authors_count(days_ago = 1)
    json_response = get_recent_cap_authorship(1, 10, days_ago)
    json_response['totalCount']
  end

  def do_science_wire_harvest
    logger.info 'authors to harvest: ' + @new_or_changed_authors_to_harvest_queue.to_s
    @sw_harvester.harvest_pubs_for_author_ids(@new_or_changed_authors_to_harvest_queue)
  end

  def process_next_batch_of_authorship_data(json_response)
    # rubocop:disable Style/GuardClause
    if json_response['count'].blank? || json_response['lastPage'].nil?
      raise "unexpected json in cap_authors_poller#process_next_batch_of_authorship_data, first 500 chars: #{json_response}"
    elsif json_response['values']
      json_response['values'].each do |record|
        begin
          @total_running_count += 1
          process_record(record)
          logger.info "Processed #{@total_running_count} authors" if @total_running_count % 10 == 0
        rescue => e
          msg = "Authorship import failed for incoming record containing: #{record.inspect if record} - #{Time.zone.now}"
          NotificationManager.handle_authorship_pull_error(e, msg)
        end
      end
    end
    # rubocop:enable Style/GuardClause
  end

  def process_record(record)
    # import_settings_exist = record["importSettings"] && record["importSettings"].any?
    cap_profile_id = record['profileId'].to_i
    author = Author.find_by_cap_profile_id(cap_profile_id)
    if author.present?
      process_record_for_existing_author(author, record)
    else
      process_record_for_new_author(cap_profile_id, record)
    end
  end

  def process_record_for_existing_author(author, record)
    logger.info "Updating author_id: #{author.id}, cap_profile_id: #{author.cap_profile_id}"
    author.update_from_cap_authorship_profile_hash(record)

    update_existing_contributions author, record['authorship'] if record['authorship'].present?

    queue_author_for_harvest author, "No import settings or author did not change. Skipping cap_profile_id: #{author.cap_profile_id}"

    author.save!
    @authors_updated_count += 1
  end

  def process_record_for_new_author(cap_profile_id, record)
    author = Author.fetch_from_cap_and_create(cap_profile_id, @cap_http_client)
    logger.info "Creating author_id: #{author.id}, cap_profile_id: #{cap_profile_id}"
    author.update_from_cap_authorship_profile_hash(record)

    if record['authorship'].present?
      # TODO: not clear to me *why* authorship is ignored for new authors...
      logger.warn "New author has authorship which will be skipped; cap_profile_id: #{cap_profile_id}"
      @new_auth_with_contribs += 1
    end

    queue_author_for_harvest author, "Author marked as not harvestable. Skipping cap_profile_id: #{cap_profile_id}"

    author.save!
    @new_author_count += 1
  end

  # Add author to job queue if it's harvestable and new/changed
  # @param [String] `skip_message` logs this message if it skips adding author to queue
  def queue_author_for_harvest(author, skip_message)
    if (author.new_record? || author.changed?) && author.harvestable?
      @new_or_changed_authors_to_harvest_queue << author.id
    else
      @no_sw_harvest_count += 1
      logger.info skip_message
    end
  end

  def update_existing_contributions(author, incoming_authorships)
    incoming_authorships.each do |authorship|
      if !Contribution.authorship_valid? authorship
        msg = "Invalid authorship: cap_profile_id: #{author.cap_profile_id}; #{authorship.inspect}"
        logger.error msg
        exception = ArgumentError.new(msg)
        NotificationManager.handle_authorship_pull_error(exception, msg)
        @invalid_contribs += 1
        next
      end
      pub_id = authorship['sulPublicationId']
      contribs = author.contributions.where(publication_id: pub_id)
      if contribs.count == 0
        logger.warn "Contribution does not exist for author_id: #{author.id}, cap_profile_id: #{author.cap_profile_id}, publication_id: #{pub_id}"
        @contrib_does_not_exist += 1
        next
      elsif contribs.count > 1
        logger.warn "More than one contribution for author_id: #{author.id}, cap_profile_id: #{author.cap_profile_id}, publication_id: #{pub_id}"
        @too_many_contribs += 1
        next
      end
      update_existing_contribution(contribs.first, authorship)
    end
  end

  def update_existing_contribution(contribution, authorship)
    hash_for_update = {
      featured: authorship['featured'],
      status: authorship['status'],
      visibility: authorship['visibility']
    }
    contribution.assign_attributes hash_for_update
    contribution_save(contribution) if contribution.changed?
  end

  def contribution_id(contribution)
    author = contribution.author
    pub = contribution.publication
    "Contribution(author_id: #{author.id}, cap_profile_id: #{author.cap_profile_id}, publication_id: #{pub.id})"
  end

  def contribution_save(contribution)
    contribution.save
    contribution_sync_to_pubhash(contribution)
    logger.info "Updated #{contribution_id(contribution)}"
    @contribs_changed += 1
  end

  def contribution_sync_to_pubhash(contribution)
    pub = contribution.publication
    pub.set_last_updated_value_in_hash
    pub.add_all_db_contributions_to_my_pub_hash
    pub.save
  end

  private

  def convert_days_ago_to_timestamp(days_ago)
    poll_time = Time.zone.now - (days_ago.to_i).days
    poll_time.iso8601(3)
  end

  # @param page_count [Fixnum]  default = 1  -- 1st page
  # @param page_size [Fixnum]   default = 10 -- 10 records
  # @param days_ago [Fixnum]    default = 1  -- within the last 24 hours
  # @return json_response
  def get_recent_cap_authorship(page_count = 1, page_size = 10, days_ago = 1)
    poll_since = convert_days_ago_to_timestamp(days_ago)
    @cap_http_client.get_batch_from_cap_api(page_count, page_size, poll_since)
  end

  def init_stats
    @start_time = Time.zone.now
    @total_running_count = 0
    @new_author_count = 0
    @authors_updated_count = 0
    @no_sw_harvest_count = 0
    @no_email_in_import_settings = 0
    @active_true_count = 0
    @active_false_count = 0
    @no_active_count = 0
    @import_enabled_count = 0
    @import_disabled_count = 0
    @contribs_changed = 0
    @contrib_does_not_exist = 0
    @invalid_contribs = 0
    @too_many_contribs = 0
    @new_auth_with_contribs = 0
  end

  def log_process_time
    distance_of_time_in_words(@start_time, Time.zone.now)
  end

  def log_stats
    info = []
    info << "#{@total_running_count} records were processed in #{log_process_time}"
    info << "#{@new_author_count} authors were created."
    info << "#{@no_sw_harvest_count} authors were not harvested because of no import settings or they did not change"
    info << "#{@no_email_in_import_settings} records with no email in import settings."
    info << "#{@active_true_count} records with 'active' true."
    info << "#{@active_false_count} records with 'active' false."
    info << "#{@no_active_count} records with no 'active' field in profile."
    info << "#{@authors_updated_count} authors were updated."
    info << "#{@import_enabled_count} authors had import enabled."
    info << "#{@import_disabled_count} authors had import disabled."
    info << "#{@contrib_does_not_exist} contributions did not exist for update"
    info << "#{@invalid_contribs} contributions were invalid authorship data"
    info << "#{@too_many_contribs} contributions had more than one instance for an author"
    info << "#{@new_auth_with_contribs} new authors had contributions which were ignored"
    info << "#{@contribs_changed} contributions were updated"
    logger.info info.join("\n")
  end
end
