server "sulcap-prod.stanford.edu", :app, :web, :db, :primary => true

set :rails_env, 'production'
set :deploy_via, :copy