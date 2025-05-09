# see https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment
server 'sul-pub-cap-dev-a.stanford.edu', user: 'pub', roles: %w(web db app)


set :rails_env, 'production'

set :bundle_without, %w(development test).join(' ')
