# Learn more: http://github.com/javan/whenever

def stagger(hour)
  ('%02d' % hour) + (':%02d' % rand(60)) # some minute between 00 and 59
end

set :output, 'log/cron.log'

# fortnightly sciencewire harvest at 5pm in qa, on the 8th and 23rd of the month
every "0 17 8,23 * *", roles: [:harvester_qa] do
  rake 'sw:fortnightly_harvest'
end

# fortnightly sciencewire harvest at 5pm in prod, on the 1st and 15th of the month
every "0 17 1,15 * *", roles: [:harvester_prod] do
  rake 'sw:fortnightly_harvest'
end

# poll cap for new authorship information nightly at 4am-ish in both prod and qa
every 1.day, at: stagger(4), roles: [:harvester_qa, :harvester_prod] do
  rake 'cap:poll[1]'
end

# ensure delayed_job is started on a reboot
every :reboot do
  command "cd :path && :environment_variable=:environment bundle exec bin/delayed_job start"
end
