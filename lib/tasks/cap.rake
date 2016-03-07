
namespace :cap do
  desc 'poll cap for new authorship information'
  task :poll, [:days_ago] => :environment do |_t, args|
    poller = CapAuthorsPoller.new
    Signal.trap('USR1') do
      poller.debug = true
    end
    poller.get_authorship_data args[:days_ago]
  end
end
