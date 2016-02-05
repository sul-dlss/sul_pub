server 'sulcap-dev.stanford.edu', user: '***REMOVED***', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'development'
set :deploy_via, :copy

# This is a development box, do not exclude development gems.
set :bundle_without, 'test'
