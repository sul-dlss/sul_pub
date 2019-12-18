# This will become the new UAT server (currently called `cap-qa`).  It will initially be used by the Profiles
#   team for testing their Oracle upgrade against.  Later we will remove the `cap-qa` host and deploy target and keep this in its place.
# Oct 30 2019, P Mangiafico
server 'sul-pub-cap-uat.stanford.edu', user: 'pub', roles: %w(web db app harvester_uat external_monitor)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'

set :bundle_without, %w(test development).join(' ')

set :log_level, :info
