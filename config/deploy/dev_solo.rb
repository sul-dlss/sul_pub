server 'sulcap-dev-solo.stanford.edu', user: '***REMOVED***', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'development'

# This is a development box, do not exclude development gems.
set :bundle_without, 'test'
