
namespace :cap do

  desc "poll cap for new authorship information"
  task :poll, [:days_ago] => :environment do |t, args|
    CapAuthorsPoller.new.get_authorship_data args[:days_ago]
    #CapAuthorshipMailer.welcome_email("some test text").deliver
  end

end
