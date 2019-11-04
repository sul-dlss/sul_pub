# This will become the new CAP-DEV server (currently called `cap-dev`).  It will initially be used by the Profiles
#   team for testing their Oracle upgrade against.  Later we will remove the `cap-dev` host and deploy target and keep this in its place.
#   We should then rename it back to `cap-dev` to match what it used to be.
# Oct 30 2019, P Mangiafico
server 'sul-pub-cap-dev-a.stanford.edu', user: 'pub', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'

set :bundle_without, %w(development test).join(' ')
