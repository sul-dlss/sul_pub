server 'sul-pub-prod.stanford.edu', user: fetch(:user), roles: %w(web db app harvester)

Capistrano::OneTimeKey.generate_one_time_key!

set :bundle_without, %w(test development).join(' ')

set :log_level, :info
