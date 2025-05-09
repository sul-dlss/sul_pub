# see https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment
server 'sul-pub-cap-uat.stanford.edu', user: 'pub', roles: %w(web db app external_monitor)


set :rails_env, 'production'

set :bundle_without, %w(test development).join(' ')

set :log_level, :info
