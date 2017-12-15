require 'json'

class FixVisibilityNil
  def initialize
    @logger = Logger.new(Rails.root.join('log', 'script_fix_visibility_nil.log'))
    @author_ids = [
      113, 447, 988, 1239, 1791, 1941, 2263, 2345, 2484, 3288, 3868,
      3948, 4222, 5231, 5393, 5604, 5779, 6142, 6659, 6945, 7369, 7930,
      8504, 9264, 9575, 9753, 12_585, 16_136, 17_350, 17_352, 17_353, 17_355,
      18_141, 18_266, 18_267, 18_281, 18_409, 18_730, 18_917, 19_173, 20_367, 21_394,
      21_955, 23_104, 25_266, 25_353, 25_645, 26_535, 28_120, 28_298, 28_645, 29_240,
      29_323, 29_516, 29_597, 29_934, 30_258, 31_792, 31_885, 32_471, 33_428, 36_820,
      52_476, 56_076]

    @logger.info "Processing #{@author_ids.count} Authors"
    @updated = 0
    @errors = 0
    @cap_http_client = CapHttpClient.new
    @poller = Cap::AuthorsPoller.new
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
