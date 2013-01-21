require 'rvm/capistrano'  # Add RVM integration
require 'bundler/capistrano'  # Add Bundler integration
load 'deploy/assets'

set :rvm_type, :system

set :application, "sulbib"

set :scm, :git
ssh_options[:forward_agent] = true
set :repository,  "git@github.com:DMSTech/sul-pub.git"
set :branch, "master"
 

role :web, "sulcap-prod.stanford.edu"                          # Your HTTP server, Apache/etc
role :app, "sulcap-prod.stanford.edu"                          # This may be the same as your `Web` server
role :db,  "sulcap-prod.stanford.edu", :primary => true # This is where Rails migrations will run

set :user, "***REMOVED***"
set :deploy_to, "/home/***REMOVED***/#{application}"
set :use_sudo, false
set :deploy_via, :remote_cache

after 'deploy:update_code', 'deploy:symlink_db'

namespace :deploy do
  desc "Symlink database.yml"
  task :symlink_db, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end
end

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end