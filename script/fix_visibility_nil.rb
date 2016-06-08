require 'json'

class FixVisibilityNil
  def initialize
    @logger = Logger.new(Rails.root.join('log', 'script_fix_visibility_nil.log'))
    @author_ids = [
      113, 447, 988, 1239, 1791, 1941, 2263, 2345, 2484, 3288, 3868,
      3948, 4222, 5231, 5393, 5604, 5779, 6142, 6659, 6945, 7369, 7930,
      8504, 9264, 9575, 9753, 12585, 16136, 17350, 17352, 17353, 17355,
      18141, 18266, 18267, 18281, 18409, 18730, 18917, 19173, 20367, 21394,
      21955, 23104, 25266, 25353, 25645, 26535, 28120, 28298, 28645, 29240,
      29323, 29516, 29597, 29934, 30258, 31792, 31885, 32471, 33428, 36820,
      52476, 56076]

    @logger.info "Processing #{@author_ids.count} Authors"
    @updated = 0
    @errors = 0
    @cap_http_client = CapHttpClient.new
    @poller = CapAuthorsPoller.new
  end

  def work
    count = 0
    @author_ids.each do |id|
      begin
        count += 1
        process id
        @updated += 1
        @logger.info "Processed #{count}" if count % 500 == 0
      rescue => e
        @errors += 1
        @logger.error "Unable to process #{id}: #{e.inspect}"
        @logger.error e.backtrace.join("\n")
      end
    end

    @logger.info "Updated #{@updated}"
    @logger.info "Errors  #{@errors}"
  end

  def process(author_id)
    author = Author.find(author_id)
    record = @cap_http_client.get_auth_profile(author.cap_profile_id)
    @logger.info "Processing Author.find(#{author_id})"
    @poller.process_record(record)
  end
end

u = FixVisibilityNil.new
u.work
