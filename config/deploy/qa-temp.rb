# see https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment
# see https://github.com/sul-dlss/operations-tasks/issues/3879
# see https://docs.google.com/document/d/14K09NJG1O6Zo8u0LfrxK5g8ADLTBZ_HzkAnEr_YAsS8
server 'sul-pub-cap-dev-temp.stanford.edu', user: 'pub', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'

set :bundle_without, %w(development test).join(' ')
