require 'dotiw'
require 'time'
class CapAuthorsPoller

  def initialize
    @sw_harvester = ScienceWireHarvester.new
    @cap_http_client = CapHttpClient.new
  end

  def debug=(val)
    write_stats_from_logging_variables_to_log
    @sw_harvester.debug = val
  end

  include ActionView::Helpers::DateHelper

  def get_authorship_data(days_ago = 1)
    begin
      poll_since = convert_days_ago_to_timestamp(days_ago)

      page_size = 1000
      page_count = 0

      @new_or_changed_authors_to_harvest_queue = []

      @cap_authorship_logger = Logger.new(Rails.root.join('log', 'cap_authorship_api.log'))
      @cap_authorship_logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      @cap_authorship_logger.formatter = proc { |severity, datetime, progname, msg|
        "#{severity} #{datetime}: #{msg}\n"
      }
      @cap_authorship_logger.info "Started authorship import - #{DateTime.now}"

      @last_page = false

      set_up_logging_variables

      until @last_page
        page_count += 1
        json_response = @cap_http_client.get_batch_from_cap_api(page_count, page_size, poll_since)
        process_next_batch_of_authorship_data(json_response)
        update_message = "#{@total_running_count} records were processed in #{distance_of_time_in_words_to_now(@start_time)}"
        puts update_message
        @cap_authorship_logger.info update_message
        @last_page = json_response["lastPage"]
      end

      write_stats_from_logging_variables_to_log
      do_science_wire_harvest

      puts "#{page_count} pages with #{page_size} records per page were processed in #{distance_of_time_in_words_to_now(@start_time)}"
      puts "#{@new_author_count} authors were created."
      @cap_authorship_logger.info "Finished authorship import"

    rescue => e
      NotificationManager.handle_authorship_pull_error(e, "Authorship import failed - #{DateTime.now}" )
    end
  end

  def cap_authors_count(days_ago = 1)
    poll_since = convert_days_ago_to_timestamp(days_ago)
    @cap_http_client.get_batch_from_cap_api(1, 10, poll_since)['totalCount']
  end

  def do_science_wire_harvest
    puts "authors to harvest: " + @new_or_changed_authors_to_harvest_queue.to_s
    @sw_harvester.harvest_pubs_for_author_ids(@new_or_changed_authors_to_harvest_queue)
  end

  def process_next_batch_of_authorship_data(json_response)
    if json_response["count"].blank? || json_response["lastPage"].nil?
      raise "unexpected json in cap_authors_poller#process_next_batch_of_authorship_data, first 500 chars: #{json_response}"
    elsif json_response["values"]
      json_response["values"].each do | record |
        begin
          @total_running_count += 1

          process_record(record)

          @cap_authorship_logger.info "Processed #{@total_running_count} authors" if @total_running_count % 10 == 0

        rescue => e
          NotificationManager.handle_authorship_pull_error(e, "Authorship import failed for incoming record containing: #{record.inspect if(record)} - #{DateTime.now}")
        end
      end
    end
  end

  def process_record(record)
    #import_settings_exist = record["importSettings"] && record["importSettings"].any?

    author = Author.find_or_initialize_by_cap_profile_id(record['profileId'])
    author.update_from_cap_authorship_profile_hash(record)

    if author.persisted?
      @cap_authorship_logger.info "Updating author_id #{author.id}"
      @authors_updated_count += 1
    else
      @cap_authorship_logger.info "Creating author for cap_profile_id #{record['profileId']}"
      @new_author_count += 1
    end

    if record["authorship"] && author.persisted?
      update_existing_contributions author, record["authorship"]
    elsif record["authorship"] && record["authorship"].size > 0 && author.new_record?
      @cap_authorship_logger.warn "New author has authorship which will be skipped. cap_profile_id: #{record['profileId']}"
      @new_auth_with_contribs += 1
    end

    author.save

    if(author.harvestable?)
      @new_or_changed_authors_to_harvest_queue << author.id
    else
      @no_import_settings_count += 1
      @cap_authorship_logger.info "No import settings. Skipping cap_profile_id #{author.cap_profile_id}"
    end
  end

  def update_existing_contributions author, incoming_authorships
    incoming_authorships.each do |authorship|

      contribs = author.contributions.where(:publication_id => authorship['sulPublicationId'])
      if contribs.count == 0
        @cap_authorship_logger.warn "Contribution does not exist- auth_id: #{author.id} publication_id: #{authorship['sulPublicationId']}"
        @contrib_does_not_exist += 1
        next
      elsif contribs.count > 1
        @cap_authorship_logger.warn "More than one contribution for auth_id: #{author.id} publication_id: #{authorship['sulPublicationId']}"
        @too_many_contribs += 1
        next
      end

      contrib = contribs.first
      hash_for_update = {
        status: authorship['status'],
        visibility: authorship['visibility'],
        featured: authorship['featured']
      }
      contrib.assign_attributes hash_for_update
      if contrib.changed?
        contrib.save
        pub = contrib.publication
        pub.set_last_updated_value_in_hash
        pub.add_all_db_contributions_to_my_pub_hash
        pub.save
        @cap_authorship_logger.info "Contribution changed for auth_id: #{author.id} publication_id: #{authorship['sulPublicationId']}"
        @contribs_changed += 1
      end
    end

  end

  def set_up_logging_variables
    @start_time = Time.now
    @total_running_count = 0
    @new_author_count = 0
    @authors_updated_count = 0
    @no_import_settings_count = 0
    @no_email_in_import_settings = 0
    @active_true_count = 0
    @active_false_count = 0
    @no_active_count = 0
    @import_enabled_count = 0
    @import_disabled_count = 0
    @contrib_does_not_exist = 0
    @too_many_contribs = 0
    @new_auth_with_contribs = 0
  end

  def write_stats_from_logging_variables_to_log
    @cap_authorship_logger.info "#{@total_running_count} records were processed in " + distance_of_time_in_words_to_now(@start_time)
    @cap_authorship_logger.info "#{@new_author_count} authors were created."
    @cap_authorship_logger.info "#{@no_import_settings_count} records with no import settings."
    @cap_authorship_logger.info "#{@no_email_in_import_settings} records with no email in import settings."
    @cap_authorship_logger.info "#{@active_true_count} records with 'active' true."
    @cap_authorship_logger.info "#{@active_false_count} records with 'active' false."
    @cap_authorship_logger.info "#{@no_active_count} records with no 'active' field in profile."
    @cap_authorship_logger.info "#{@authors_updated_count} authors were updated."
    @cap_authorship_logger.info "#{@import_enabled_count} authors had import enabled."
    @cap_authorship_logger.info "#{@import_disabled_count} authors had import disabled."
    @cap_authorship_logger.info "#{@contrib_does_not_exist} contributions did not exist for update"
    @cap_authorship_logger.info "#{@too_many_contribs} contributions had more than one instance for an author"
    @cap_authorship_logger.info "#{@new_auth_with_contribs} new authors had contributions which were ignored"
  end

private
  def convert_days_ago_to_timestamp(days_ago)
    poll_time = Time.now - (days_ago.to_i).days
    poll_time.iso8601(3)
  end

end
