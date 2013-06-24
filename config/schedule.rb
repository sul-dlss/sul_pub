#set :output, "/home/***REMOVED***/sulbib/current/log/cron_log.log"
set :output, "/Users/jameschartrand/Documents/rubyprojects/sulbib/log/cron_log.log"
#

# nightly sciencewire harvest
# this instead gets done as part of the cap authorship call, since the 
# nightly harvest is exactly for those new or changed authorhsip files that
# come in through the cap authorship feed.
#every :day, :at => '4:00am' do
 #  rake "sw:nightly_harvest", :environment => 'development' 
 #end

# fortnightly sciencewire harvest on the 1st and 15th
every '00 01 1,15 * *' do
   rake "sw:fortnightly_harvest", :environment => 'development' 
 end

# nightly cap authorship pull
every :day, :at => '1:00am' do
   rake "cap:authorship", :environment => 'development' 
 end

# cron syntax:
#minute (0-59),
#hour (0-23),
#day of the month (1-31),
#month of the year (1-12),
#day of the week (0-6 with 0=Sunday).

