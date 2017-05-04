
namespace :sul do
  desc 'Update pub_hash or authorship for all pubs'
  # bundle exec rake sul:update_pubs['rebuild_pub_hash'] # for pub hash rebuild
  # bundle exec rake sul:update_pubs['rebuild_authorship'] # for authorship rebuild
  task :update_pubs, [:method] => :environment do |_t, args|
    logger = Logger.new(Rails.root.join('log', 'update_pubs.log'))
    method = args[:method] || "rebuild_pub_hash" # default to rebuilding pub_hash, could also rebuild_authorship
    raise "Method #{method} not defined" unless Publication.new.respond_to? method
    $stdout.sync = true # flush output immediately
    include ActionView::Helpers::NumberHelper # for nice display output and time computations in output
    include ActionView::Helpers::DateHelper
    total_pubs = Publication.count
    error_count = 0
    success_count = 0
    start_time = Time.now
    output_each = 500
    max_errors = 500
    message = "Calling #{method} for #{number_with_delimiter(total_pubs)} publications.  Started at #{start_time}.  Status update shown each #{output_each} publications."
    puts message
    logger.info message
    Publication.find_each.with_index do |pub, index|
      current_time = Time.now
      elapsed_time = current_time - start_time
      avg_time_per_pub = elapsed_time/(index+1)
      total_time_remaining = (avg_time_per_pub * (total_pubs-index)).floor
      if index % output_each == 0 # provide some feedback every X pubs
        message = "...#{current_time}: on publication #{number_with_delimiter(index+1)} of #{number_with_delimiter(total_pubs)} : ~ #{distance_of_time_in_words(start_time,start_time + total_time_remaining.seconds)} left"
        logger.info message
      end
      begin
        pub.send(method)
        pub.save
        success_count += 1
      rescue  => e
        message = "*****ERROR on publication ID #{pub.id}: #{e.message}"
        puts message
        logger.error message
        error_count += 1
      end      
      if error_count > max_errors
        raise "Halting: Maximum number of errors #{max_errors} reached"
      end
    end
    message = "Total: #{number_with_delimiter(total_pubs)}.  Successful: #{success_count}.  Error: #{error_count}.  Ended at #{Time.now}"
    puts message
    logger.info message
  end

  desc 'check external services'
  task :check_external_services, [:server] => :environment do |_t, args|
    conn = Faraday.new(:url=>args[:server])
    external_checks=%w{external-CapHttpClient external-ScienceWireClient external-PubmedClient}
    external_checks.each do |check_name|
      response = conn.get "/status/#{check_name}"
      puts "#{Time.now}: #{check_name}: #{response.status} - #{response.body}"
    end
  end
end
