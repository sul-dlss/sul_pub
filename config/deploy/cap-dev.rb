server 'sul-pub-cap-dev.stanford.edu', user: 'pub', roles: %w(web db harvester_dev app)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'

set :bundle_without, %w(development test).join(' ')
