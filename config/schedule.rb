# Learn more: http://github.com/javan/whenever
require_relative 'environment'

# These define jobs that checkin with Honeybadger.
# If changing the schedule of one of these jobs, also update at https://app.honeybadger.io/projects/77112/check_ins
job_type :rake_hb,
         'cd :path && :environment_variable=:environment bundle exec rake --silent ":task" :output && curl --silent https://api.honeybadger.io/v1/check_in/:check_in'

def stagger(hour)
  ('%02d' % hour) + (':%02d' % rand(60)) # some minute between 00 and 59
end

set :output, 'log/cron.log'

# bi-weekly harvest at 5pm in qa, on the 8th and 23rd of the month
every "0 17 7,23 * *", roles: [:harvester_qa] do
  set :check_in, Settings.honeybadger_checkins.harvest_all_authors
  rake_hb 'harvest:all_authors_update'
end

# every three day harvest at 5pm in prod, don't overlap with qa
every "0 17 1,5,9,13,17,21,25,29 * *", roles: [:harvester_prod] do
  set :check_in, Settings.honeybadger_checkins.harvest_all_authors
  rake_hb 'harvest:all_authors_update'
end

# poll cap for new authorship information nightly at 4am-ish in prod, qa and dev
every 1.day, at: stagger(4), roles: [:harvester_dev, :harvester_qa, :harvester_prod] do
  set :check_in, Settings.honeybadger_checkins.cap_poll
  rake_hb 'cap:poll[1]'
end

# poll mais for new ORCID information nightly at 5am-ish in prod, qa and dev
every 1.day, at: stagger(5), roles: [:harvester_dev, :harvester_qa, :harvester_prod] do
  set :check_in, Settings.honeybadger_checkins.mais_update_authors
  rake_hb 'mais:update_authors'
end

# send publications to ORCID profiles for all authorized users at 8am-ish every 7 days in qa
every 7.days, at: stagger(8), roles: [:harvester_qa] do
  set :check_in, Settings.honeybadger_checkins.orcid_all_all_works
  rake_hb 'orcid:add_all_works'
end

# send publications to ORCID profiles for all authorized users at 6am-ish every 2 days in prod
every 2.days, at: stagger(6), roles: [:harvester_prod] do
  set :check_in, Settings.honeybadger_checkins.orcid_all_all_works
  rake_hb 'orcid:add_all_works'
end
