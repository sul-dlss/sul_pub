# see https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment
server 'sul-pub-cap-uat.stanford.edu', user: 'pub', roles: %w(web db app harvester_qa external_monitor)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'

set :bundle_without, %w(test development).join(' ')

set :log_level, :info
