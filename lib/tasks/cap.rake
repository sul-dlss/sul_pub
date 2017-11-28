
namespace :cap do
  desc 'poll cap for new authorship information'
  task :poll, [:days_ago] => :environment do |_t, args|
    poller = CapAuthorsPoller.new
    Signal.trap('USR1') do
      poller.debug = true
    end
    poller.get_authorship_data args[:days_ago]
  end

  desc 'poll cap for an author (print data only)'
  task :poll_data_for_cap_profile_id, [:cap_profile_id] => :environment do |_t, args|
    raise "cap_profile_id argument is required." unless args[:cap_profile_id].present?
    cap_http_client = Cap::Client.new
    record = cap_http_client.get_auth_profile(args[:cap_profile_id])
    puts JSON.pretty_generate(record)
  end

  desc 'poll cap for an author (process data)'
  task :poll_for_cap_profile_id, [:cap_profile_id] => :environment do |_t, args|
    raise "cap_profile_id argument is required." unless args[:cap_profile_id].present?
    cap_http_client = Cap::Client.new
    record = cap_http_client.get_auth_profile(args[:cap_profile_id])
    poller = CapAuthorsPoller.new
    poller.process_record(record)
  end
end
