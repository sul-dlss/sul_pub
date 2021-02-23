# see https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment
server 'sul-pub-stage.stanford.edu', user: 'pub', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'

set :bundle_without, %w(test development).join(' ')

set :log_level, :info
