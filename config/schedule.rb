# Learn more: http://github.com/javan/whenever
job_type :envcommand, 'cd :path && RAILS_ENV=:environment :bundle_command :task :output'

def stagger(hour)
  ('%02d' % hour) + (':%02d' % rand(60)) # some minute between 00 and 59
end

set :output, 'log/cron.log'

# bi-weekly harvest at 5pm in qa, on the 8th and 23rd of the month
every "0 17 7,23 * *", roles: [:harvester_qa] do
  rake 'harvest:all_authors_update'
end

# every three day harvest at 5pm in prod, don't overlap with qa
every "0 17 1,5,9,13,17,21,25,29 * *", roles: [:harvester_prod] do
  rake 'harvest:all_authors_update'
end

# poll cap for new authorship information nightly at 4am-ish in prod, qa and dev
every 1.day, at: stagger(4), roles: [:harvester_dev, :harvester_qa, :harvester_prod] do
  rake 'cap:poll[1]'
end

# poll mais for new ORCID information nightly at 5am-ish in prod, qa and dev
every 1.day, at: stagger(5), roles: [:harvester_dev, :harvester_qa, :harvester_prod] do
  rake 'mais:update_authors'
end

# send publications to ORCID profiles for all authorized users at 6am-ish every 3 days in qa and dev
# when validation is complete, we will add the :harvester_prod role and remove this comment
every 3.days, at: stagger(6), roles: [:harvester_dev, :harvester_qa] do
  rake 'orcid:add_all_works'
end

# ensure delayed_job is started on a reboot
every :reboot do
  envcommand 'bin/delayed_job -n 2 start'
end
