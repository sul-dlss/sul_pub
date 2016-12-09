# Learn more: http://github.com/javan/whenever

def stagger(hour)
  ('%02d' % hour) + (':%02d' % rand(60)) # some minute between 00 and 59
end

set :output, 'log/cron.log'

# fortnightly sciencewire harvest at 5pm-ish
every 2.weeks, at: stagger(17), roles: [:harvester] do
  rake 'sw:fortnightly_harvest'
end

# poll cap for new authorship information nightly at 4am-ish
every 1.day, at: stagger(4), roles: [:harvester] do
  rake 'cap:poll[1]'
end

# call a rake task that hits the OK computer external checks, triggering honeybadger notifications if there is an error
every 30.minutes, roles: [:external_monitor] do
  rake "sul:check_external_services[\"https://#{`hostname`.chomp!}\"]"
end
