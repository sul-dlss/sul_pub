require 'dotiw'
require 'time'

module Cap

  class AuthorsPoller
    include ActionView::Helpers::DateHelper

    def initialize
      @sw_harvester = ScienceWireHarvester.new
      @cap_client = Cap::Client.new
      @logger = NotificationManager.cap_logger
      init_stats
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
          NotificationManager.error(e, 'get_authorship_data iteration failed', self)
          raise
        end
      end

      log_stats
      logger.info 'authors to harvest: ' + @new_or_changed_authors_to_harvest_queue.to_s
      do_science_wire_harvest
      do_wos_harvest

      info = []
      info << "#{page_count} pages with #{page_size} records were processed in #{log_process_time}"
      info << "#{@new_author_count} authors were created."
      info << 'Finished authorship import'
      logger.info info.join("\n")
    rescue => e
      NotificationManager.error(e, 'Authorship import failed', self)
    end

    def cap_authors_count(days_ago = 1)
      json_response = get_recent_cap_authorship(1, 10, days_ago)
      json_response['totalCount']
    end

    def do_science_wire_harvest
      return unless Settings.SCIENCEWIRE.enabled
      @sw_harvester.harvest_pubs_for_author_ids(@new_or_changed_authors_to_harvest_queue)
    end

    def do_wos_harvest
      return unless Settings.WOS.enabled
      Author.where(id: @new_or_changed_authors_to_harvest_queue).find_in_batches(batch_size: 250) do |authors|
        WebOfScience.harvester.harvest(authors)
      end
    end

    def process_next_batch_of_authorship_data(json_response)
      if json_response['count'].blank? || json_response['lastPage'].nil?
        raise Net::HTTPBadResponse, "Missing JSON data in response: first 500 chars: #{json_response[0..500]}"
      end
      return unless json_response['values']
      json_response['values'].each do |record|
        begin
          @total_running_count += 1
          process_record(record)
          log_stats if @total_running_count % 10 == 0
        rescue => e
          NotificationManager.error(e, "Authorship import failed for record: '#{record}'", self)
        end
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
        if !Contribution.valid_fields? authorship
          msg = "Invalid fields in authorship: Author.find_by(cap_profile_id: #{author.cap_profile_id}); #{authorship.inspect}"
          NotificationManager.error(ArgumentError.new(msg), msg, self)
          @invalid_contribs += 1
          next
        end
        pub_id = authorship['sulPublicationId']
        contribs = author.contributions.where(publication_id: pub_id)
        if contribs.count == 0
          logger.warn "Contribution does not exist for Contribution.find_by(author_id: #{author.id}, cap_profile_id: #{author.cap_profile_id}, publication_id: #{pub_id})"
          @contrib_does_not_exist += 1
          next
        elsif contribs.count > 1
          logger.warn "More than one contribution for Contribution.where(author_id: #{author.id}, cap_profile_id: #{author.cap_profile_id}, publication_id: #{pub_id})"
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

      def process_record_for_existing_author(author, record)
        logger.info "Updating Author.find_by(id: #{author.id}, cap_profile_id: #{author.cap_profile_id})"
        author.update_from_cap_authorship_profile_hash(record)
        update_existing_contributions author, record['authorship'] if record['authorship'].present?
        queue_author_for_harvest(author)
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
        queue_author_for_harvest(author)
        author.save!
        @new_author_count += 1
      end

      # Add author to job queue if it's harvestable and new/changed
      # @param [String] `skip_message` logs this message if it skips adding author to queue
      def queue_author_for_harvest(author)
        if (author.new_record? || author.changed?) && author.harvestable?
          @new_or_changed_authors_to_harvest_queue << author.id
        else
          @no_sw_harvest_count += 1
          logger.info "Author marked as not harvestable or did not change. Skipping Author.find_by(cap_profile_id: #{author.cap_profile_id})"
        end
      end
  end
end
