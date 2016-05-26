#
# Execute using `bundle exec rails runner script/refresh_existing_authors.rb`
#
class RefreshExistingAuthors

  attr_reader :logger

  def initialize
    @logger = Logger.new(Rails.root.join('log', 'refresh_existing_authors.log'))
    @logger.level = Logger::INFO
  end

  def work
    @start_time = Time.zone.now
    logger.info "Started CAP author refreshing - #{@start_time}"
    fetch_cap_authors
    logger.info "Finished CAP author refreshing - #{log_process_time}"
  rescue => e
    msg = "#{e.inspect}\n"
    msg += e.backtrace.join("\n")
    logger.error msg
  end

  private

    def cap_client
      @cap_client ||= CapHttpClient.new
    end

    # Queries the CAP API for all the authors
    def fetch_cap_authors
      page_count = 0
      page_size = 50 # this is the maximum page size observed in QA environment on 4/20/16
      loop do
        begin
          page_count += 1
          json_data = cap_client.get_batch_from_cap_api(page_count, page_size)
          json_data['values'].each do |author_hash|
            process_author(author_hash)
          end
          logger.info "#{page_count * page_size} (#{json_data['count']}) records processed in #{log_process_time}"
          break if json_data['lastPage'].present? || json_data['count'].to_i < 1 || json_data['values'].blank?
        rescue => e
          logger.error e.inspect
          raise # this is a catastrophic failure and should halt processing
        end
      end
    end

    # For *existing* authors, we update their identities with data from the given CAP API data
    # This code mimics what CapAuthorsPoller does by calling `update_from_cap_authorship_profile_hash` then `save!`
    # @param [Hash] `author_hash` the author data from the CAP API
    def process_author(author_hash)
      cap_profile_id = author_hash['profileId'].to_i
      author = Author.find_by_cap_profile_id(cap_profile_id)
      if author.present?
        logger.debug("Refreshing existing author: cap_profile_id=#{cap_profile_id}")
        author.update_from_cap_authorship_profile_hash(author_hash)
        author.save!
      else
        # New authors will be ingested via `rake cap:poll`
        logger.debug("Skipping refresh of new author: cap_profile_id=#{cap_profile_id}")
      end
    rescue ActiveRecord::RecordInvalid => e
      logger.error("Error processing cap_profile_id=#{cap_profile_id}: #{e.inspect}")
      logger.debug(author_hash.inspect)
    end

    def log_process_time
      format("%6.2f min", (Time.zone.now - @start_time) / 60.0)
    end
end

# MAIN
RefreshExistingAuthors.new.work
