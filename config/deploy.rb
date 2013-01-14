require 'rvm/capistrano'  # Add RVM integration
require 'bundler/capistrano'  # Add Bundler integration
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
set :deploy_to, "/home/***REMOVED***/BibApp"
set :use_sudo, false
set :deploy_via, :remote_cache

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