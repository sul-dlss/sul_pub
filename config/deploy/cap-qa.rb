server 'sul-pub-cap-qa.stanford.edu', user: fetch(:user), roles: %w(web db app harvester external_monitor)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'

set :bundle_without, %w(test development).join(' ')

set :log_level, :info
