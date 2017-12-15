# @deprecated
# This class was only ever used on Stage/Cap-QA servers.  It exists because our non-production
# servers connect to non-production CAP Profile servers to retrieve authors, and those servers
# have different (`cap_profile_id`) primary keys than their production counterparts.  So if we
# clone data from production, we still have to realign `cap_profile_id` to match the new backend.
#
# This code:
# - Matches existing authors on :sunetid, :university_id, :california_physician_license
#   - overwrites attributes including cap_profile_id
#   - updates `cap_profile_id` in related contributions (presumed changed)
# - Creates new authors where data is unmatched
module Cap
  class ProfileIdRewriter
    include ActionView::Helpers::DateHelper

    # We intentionally deferred adapting this class to tolerate or workaround cap_profile_id
    # uniqueness, since it is unclear when, if ever, we would be using this again.
    # If it becomes needed, development will need to solve the problem
    def initialize
      raise 'Cap::ProfileIdRewriter disabled'
    end

    # @param [Integer] starting the "page" of results to start from
    # @return [void]
    def rewrite_cap_profile_ids_from_feed(starting = 0)
      logger.info "Started cap profile id rewrite at #{start_time}"
      logger.info 'CAP API client config: '
      logger.info client.auth.to_json
      counts[:page_count] = starting
      until process_next_batch_of_authorship_data(counts[:page_count], 1000)
        counts[:page_count] += 1
        logger.info "#{counts[:total_running_count]} records processed in #{distance_of_time_in_words_to_now(start_time, true)}"
      end
    rescue => e
      NotificationManager.log_exception(logger, "cap profile id rewrite import failed", e)
    ensure
      write_counts_to_log
    end

    private

      # @return [Logger]
      def logger
        @logger ||= Logger.new(Settings.CAP.PROFILE_ID_REWRITE_LOG)
      end

      # @return [ActiveSupport::TimeWithZone]
      def start_time
        @start_time ||= Time.zone.now
      end

      # @return [Hash<Symbol => Integer>]
      def counts
        @counts ||= Hash.new { 0 } # default 0
      end

      # @return [CapHttpClient]
      def client
        @client ||= CapHttpClient.new
      end

      def write_counts_to_log
        stats = "Finished cap profile id rewrite\n"
        stats += "#{counts[:total_running_count]} records were processed in #{distance_of_time_in_words_to_now(start_time)}\n"
        stats += "#{counts[:authors_updated_count]} authors were updated.\n"
        stats += "#{counts[:new_author_count]} authors were created.\n"
        stats += "Pages of 1000 records were processed up to page #{counts[:page_count]}.\n"
        logger.info stats
      end

      # @param [Integer] page
      # @param [Integer] page_size
      # @return [Boolean] true when JSON response indicates 'lastPage'
      def process_next_batch_of_authorship_data(page, page_size)
        json_response = client.get_batch_from_cap_api(page, page_size, nil)
        if json_response['values'].blank?
          logger.warn "Authorship import ended unexpectedly: unexpected json: #{json_response}"
          raise
        end
        json_response['values'].each do |record|
          counts[:total_running_count] += 1
          attrs = Author.build_attribute_hash_from_cap_profile(record)
          good_keys = [:sunetid, :university_id, :california_physician_license].select { |key| attrs[key].present? }
          author = good_keys.inject(nil) { |memo, key| memo || Author.find_by(key => attrs[key]) } # first hit wins

          if author
            author.update_attributes!(attrs) # update_attributes! does validations, but update_attribute skips them
            author.contributions.each { |contrib| contrib.update_attribute(:cap_profile_id, author.cap_profile_id) }
            counts[:authors_updated_count] += 1
          else # SKIP new authors?
            Author.create!(attrs)
            counts[:new_author_count] += 1
          end
        end
        json_response['lastPage']
      end
  end
end
