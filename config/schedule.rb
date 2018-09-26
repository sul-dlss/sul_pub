# Learn more: http://github.com/javan/whenever
job_type :envcommand, 'cd :path && RAILS_ENV=:environment :bundle_command :task :output'

def stagger(hour)
  ('%02d' % hour) + (':%02d' % rand(60)) # some minute between 00 and 59
end

set :output, 'log/cron.log'

# bi-weekly harvest at 5pm in qa, on the 8th and 23rd of the month
every "0 17 7,23 * *", roles: [:harvester_qa] do
  rake 'wos:harvest_authors_update'
end

# every three day harvest at 5pm in prod, don't overlap with qa
every "0 17 1,5,9,13,17,21,25,29 * *", roles: [:harvester_prod] do
  rake 'wos:harvest_authors_update'
end

# poll cap for new authorship information nightly at 4am-ish in both prod and qa
every 1.day, at: stagger(4), roles: [:harvester_qa, :harvester_prod, :harvester_dev] do
  rake 'cap:poll[1]'
end

# ensure delayed_job is started on a reboot
every :reboot do
  envcommand 'bin/delayed_job -n 2 start'
end
