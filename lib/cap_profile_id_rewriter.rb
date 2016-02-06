require 'dotiw'
class CapProfileIdRewriter
  include ActionView::Helpers::DateHelper

  def cap_authorship_logger
    @cap_authorship_logger ||= begin
      Logger.new(Rails.root.join('log', 'cap_profile_id_rewrite.log'))
    end
  end

  def rewrite_cap_profile_ids_from_feed(starting = 0)
    @cap_http_client = CapHttpClient.new
    cap_authorship_logger.info "Started cap profile id rewrite  - #{Time.zone.now}"
    cap_authorship_logger.info 'CAP API client config: '
    cap_authorship_logger.info @cap_http_client.auth.to_json

    @page_count = starting
    @last_page = false
    initialize_counts_for_logging
    until @last_page
      @page_count += 1
      process_next_batch_of_authorship_data(@page_count, 1000)
      Rails.logger.debug "#{@total_running_count} in #{distance_of_time_in_words_to_now(@start_time, true)}"
      cap_authorship_logger.info @total_running_count.to_s + ' records were processed in ' + distance_of_time_in_words_to_now(@start_time)

      # if page_count === 1 then break end
    end
    write_counts_to_log

  rescue => e
    cap_authorship_logger.error "cap profile id rewrite import failed - #{Time.zone.now}"
    cap_authorship_logger.error e.message
    cap_authorship_logger.error e.backtrace.join("\n")
    Rails.logger.warn e.message
    Rails.logger.info e.backtrace
  end

  def initialize_counts_for_logging
    @start_time = Time.zone.now
    @total_running_count = 0
    @new_author_count = 0
    @authors_updated_count = 0
    @no_import_settings_count = 0
    @no_email_in_import_settings = 0
    @active_true_count = 0
    @active_false_count = 0
    @no_profile_email_count =
    @no_active_count = 0
    @import_enabled_count = 0
    @import_disabled_count = 0
  end

  def write_counts_to_log
    stats = "Finished cap profile id rewrite - #{Time.zone.now}"
    stats += "#{@total_running_count} records were processed in " + distance_of_time_in_words_to_now(@start_time)
    stats += "#{@new_author_count} authors were created."
    stats += "#{@no_import_settings_count} records with no import settings."
    stats += "#{@no_email_in_import_settings} records with no email in import settings."
    stats += "#{@active_true_count} records with 'active' true."
    stats += "#{@active_false_count} records with 'active' false."
    stats += "#{@no_active_count} records with no 'active' field in profile."
    stats += "#{@authors_updated_count} authors were updated."
    stats += "#{@import_enabled_count} authors had import enabled."
    stats += "#{@import_disabled_count} authors had import disabled."
    cap_authorship_logger.info stats
    Rails.logger.info @new_author_count.to_s + ' authors were created.'
    Rails.logger.info @page_count.to_s + ' pages of 1000 records were processed in ' + distance_of_time_in_words_to_now(@start_time)
    Rails.logger.info @total_running_count.to_s + ' total records were processed in ' + distance_of_time_in_words_to_now(@start_time)
  end

  def process_next_batch_of_authorship_data(page_count, page_size)
    json_response = @cap_http_client.get_batch_from_cap_api(page_count, page_size, nil)

    if json_response['values'].blank?
      Rails.logger.warn 'unexpected json: ' + json_response.to_s
      cap_authorship_logger.info 'Authorship import ended unexpectedly. Returned json: '
      cap_authorship_logger.info json_response.to_s
      # TODO: send an email here.
      fail
    else
      json_response['values'].each do |record|
        @total_running_count += 1

        attrs = Author.build_attribute_hash_from_cap_profile(record)

        unless attrs[:sunetid].blank?
          author = Author.where(sunetid: attrs[:sunetid]).first
        end
        if author.nil? && !attrs[:university_id].blank?
          author = Author.where(university_id: attrs[:university_id]).first
        end
        if author.nil? && !attrs[:california_physician_license].blank?
          author = Author.where(california_physician_license: attrs[:california_physician_license]).first
        end
        if author
          author.update_attributes(attrs)
          author.contributions.each { |contrib| contrib.update_attribute(:cap_profile_id, author.cap_profile_id) }
          @authors_updated_count += 1
        else
          # SKIP new authors?
          author = Author.create(attrs)
          @new_author_count += 1
        end
      end
      @last_page = json_response['lastPage']
    end
  end
end
