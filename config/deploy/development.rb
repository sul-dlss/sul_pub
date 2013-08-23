server "sulcap-dev.stanford.edu", :app, :web, :db, :primary => true

set :rails_env, 'development'
set :deploy_via, :copy

set :branch, 'batch-feature'