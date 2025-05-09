# see https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment
# see https://github.com/sul-dlss/operations-tasks/issues/3879
# see https://docs.google.com/document/d/14K09NJG1O6Zo8u0LfrxK5g8ADLTBZ_HzkAnEr_YAsS8
server 'sul-pub-cap-uat-temp.stanford.edu', user: 'pub', roles: %w(web db app external_monitor)


set :rails_env, 'production'

set :bundle_without, %w(test development).join(' ')

set :log_level, :info
