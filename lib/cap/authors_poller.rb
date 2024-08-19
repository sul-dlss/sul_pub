# frozen_string_literal: true

require 'dotiw'
require 'time'

module Cap
  class AuthorsPoller
    include ActionView::Helpers::DateHelper

    def initialize
      @cap_client = Cap::Client.new
      @logger = NotificationManager.cap_logger
      init_stats
    end

    def get_authorship_data(days_ago = 1)
      @start_time = Time.zone.now
      logger.info "Started CAP authorship import - #{@start_time}"
      @new_authors_to_harvest_queue = []
      @changed_authors_to_harvest_queue = []
      page_count = 0
      page_size = 100 # 100 seems to be the maximum page size supported by the CAP API
      @total_records = cap_authors_count(days_ago)
      logger.info "#{@total_records} authors to process"
      loop do
        page_count += 1
        json_response = get_recent_cap_authorship(page_count, page_size, days_ago)
        process_next_batch_of_authorship_data(json_response)
        logger.info "*** #{@total_running_count} records were processed in #{log_process_time}"
        break if json_response['lastPage']
      rescue StandardError => e
        NotificationManager.error(e, 'get_authorship_data iteration failed', self)
        raise
      end

      logger.info "new authors to harvest: #{@new_authors_to_harvest_queue}"
      logger.info "changed authors to harvest: #{@changed_authors_to_harvest_queue}" if Settings.CAP.HARVEST_ON_CHANGE
      do_harvest
      log_stats
      logger.info 'Finished authorship import'
    rescue StandardError => e
      NotificationManager.error(e, 'Authorship import failed', self)
    end

    def cap_authors_count(days_ago = 1)
      json_response = get_recent_cap_authorship(1, 10, days_ago)
      json_response['totalCount']
    end

    def do_harvest
      new_author_options = {
        load_time_span: Settings.WOS.new_author_timeframe,
        relDate: Settings.PUBMED.new_author_timeframe
      }
      update_author_options = {
        load_time_span: Settings.WOS.update_timeframe,
        relDate: Settings.PUBMED.update_timeframe
      }
      Author.where(id: @new_authors_to_harvest_queue).find_in_batches(batch_size: 250) do |authors|
        AllSources.harvester.harvest(authors, new_author_options)
      end
      Author.where(id: @changed_authors_to_harvest_queue).find_in_batches(batch_size: 250) do |authors|
        AllSources.harvester.harvest(authors, update_author_options)
      end
    end

    def process_next_batch_of_authorship_data(json_response)
      if json_response['count'].blank? || json_response['lastPage'].nil?
        raise Net::HTTPBadResponse,
              "Missing JSON data in response: first 500 chars: #{json_response[0..500]}"
      end
      return unless json_response['values']

      json_response['values'].each do |record|
        @total_running_count += 1
        process_record(record)
        logger.info "*** [processing #{@total_running_count} of #{@total_records}]" if @total_running_count % 10 == 0
      rescue StandardError => e
        NotificationManager.error(e, "Authorship import failed for record: '#{record}'", self)
      end
    end

    def process_record(record)
      cap_profile_id = record['profileId'].to_i
      author = Author.find_by_cap_profile_id(cap_profile_id)
      if author.present?
        process_record_for_existing_author(author, record)
      else
        process_record_for_new_author(cap_profile_id, record)
      end
    end

    def update_existing_contributions(author, incoming_authorships)
      incoming_authorships.each do |authorship|
        unless Contribution.valid_fields? authorship
          msg = "Invalid fields in authorship: Author.find_by(cap_profile_id: #{author.cap_profile_id}); #{authorship.inspect}"
          NotificationManager.error(ArgumentError.new(msg), msg, self)
          @invalid_contribs += 1
          next
        end
        pub_id = authorship['sulPublicationId']
        contribs = author.contributions.where(publication_id: pub_id)
        if contribs.count == 0
          logger.warn "Contribution does not exist for Contribution.find_by(author_id: #{author.id}, " \
                      "cap_profile_id: #{author.cap_profile_id}, publication_id: #{pub_id})"
          @contrib_does_not_exist += 1
          next
        elsif contribs.count > 1
          logger.warn "More than one contribution for Contribution.where(author_id: #{author.id}, " \
                      "cap_profile_id: #{author.cap_profile_id}, publication_id: #{pub_id})"
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
      "Contribution.find_by(author_id: #{author.id}, cap_profile_id: #{author.cap_profile_id}, publication_id: #{pub.id})"
    end

    def contribution_save(contribution)
      contribution.save
      contribution.publication.pubhash_needs_update!
      contribution.publication.save
      logger.info "Updated #{contribution_id(contribution)}"
      @contribs_changed += 1
    end

    private

    attr_reader :logger

    def convert_days_ago_to_timestamp(days_ago)
      poll_time = Time.zone.now - days_ago.to_i.days
      poll_time.iso8601(3)
    end

    # @param page_count [Integer]  default = 1  -- 1st page
    # @param page_size [Integer]   default = 10 -- 10 records
    # @param days_ago [Integer]    default = 1  -- within the last 24 hours
    # @return json_response
    def get_recent_cap_authorship(page_count = 1, page_size = 10, days_ago = 1)
      poll_since = convert_days_ago_to_timestamp(days_ago)
      @cap_client.get_batch_from_cap_api(page_count, page_size, poll_since)
    end

    def init_stats
      @start_time = Time.zone.now
      @total_running_count = 0
      @new_author_count = 0
      @authors_updated_count = 0
      @no_harvest_count = 0
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
      info << 'FINAL TOTAL STATS:'
      info << "#{@total_records} records were returned"
      info << "#{@total_running_count} records were processed in #{log_process_time}"
      info << "#{@new_author_count} authors were created."
      info << "#{@new_authors_to_harvest_queue.size} new authors were harvested."
      info << "#{@changed_authors_to_harvest_queue.size} changed authors were harvested." if Settings.CAP.HARVEST_ON_CHANGE
      info << "#{@no_harvest_count} authors were marked as not harvestable because of import settings."
      info << "#{@authors_updated_count} authors were updated."
      info << "#{@contrib_does_not_exist} contributions did not exist for update"
      info << "#{@invalid_contribs} contributions were invalid authorship data"
      info << "#{@too_many_contribs} contributions had more than one instance for an author"
      info << "#{@new_auth_with_contribs} new authors had contributions which were ignored"
      info << "#{@contribs_changed} contributions were updated"
      info << "~#{Publication.where(created_at: @start_time..).count} publications were created."
      info << "~#{Contribution.where(created_at: @start_time..).count} contributions were created."
      logger.info info.join("\n")
    end

    def process_record_for_existing_author(author, record)
      logger.info "Updating Author.find_by(id: #{author.id}, cap_profile_id: #{author.cap_profile_id})"
      author.update_from_cap_authorship_profile_hash(record)
      update_existing_contributions author, record['authorship'] if record['authorship'].present?
      queue_author_for_harvest(author, new_record: false)
      author.save!
      @authors_updated_count += 1
    end

    def process_record_for_new_author(cap_profile_id, record)
      author = Author.fetch_from_cap_and_create(cap_profile_id, @cap_client)
      logger.info "Creating Author.find_by(id: #{author.id}, cap_profile_id: #{cap_profile_id})"
      author.update_from_cap_authorship_profile_hash(record)
      if record['authorship'].present?
        # TODO: not clear to me *why* or even *if* authorship is ignored for new authors...
        logger.warn "New author has authorship which will be skipped; Author.find_by(cap_profile_id: #{cap_profile_id})"
        @new_auth_with_contribs += 1
      end
      queue_author_for_harvest(author, new_record: true)
      author.save!
      @new_author_count += 1
    end

    # Add author to job queue if it's harvestable and new/changed
    # @param [String] `skip_message` logs this message if it skips adding author to queue
    def queue_author_for_harvest(author, options)
      if author.harvestable?
        @new_authors_to_harvest_queue << author.id if options[:new_record]
        @changed_authors_to_harvest_queue << author.id if Settings.CAP.HARVEST_ON_CHANGE && !options[:new_record] && author.should_harvest?
      else
        @no_harvest_count += 1
        logger.info "Author marked as not harvestable. Skipping Author.find_by(cap_profile_id: #{author.cap_profile_id})"
      end
    end
  end
end
