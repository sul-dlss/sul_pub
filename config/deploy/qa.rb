server "sulcap-qa.stanford.edu", user: '***REMOVED***', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'
set :deploy_via, :copy