#require 'rvm/capistrano'  # Add RVM integration
require 'bundler/capistrano'  # Add Bundler integration
require 'capistrano/ext/multistage' 

#role :app, "sul-lyberservices-dev.stanford.edu"

set :stages, ["development", "staging", "production", "qa"]
set :default_stage, "staging"

#set :rvm_type, :system
#set :rvm_path, "/usr/local/rvm"

set :application, "sulbib"

#set :whenever_command, "bundle exec whenever"
#set :whenever_environment, defer { deploy_env }
#set :whenever_roles, [:app, :db]
#require "whenever/capistrano"

set :scm, :git
ssh_options[:forward_agent] = true
set :repository,  "git@github.com:DMSTech/sul-pub.git"
set :branch, "master"

set :user, "***REMOVED***"
set :deploy_to, "/home/***REMOVED***/#{application}"
set :use_sudo, false
set :deploy_via, :remote_cache


after 'deploy:update_code', 'deploy:symlink_db', 'deploy:symlink_sw_auth', 'deploy:symlink_cap_auth'

load 'deploy/assets'

namespace :deploy do
  desc "Symlink database.yml"
  task :symlink_db, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end
  desc "Symlink sciencewire_auth.yaml"
  task :symlink_sw_auth, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/sciencewire_auth.yaml #{release_path}/config/sciencewire_auth.yaml"
  end
  desc "Symlink cap_auth.yaml"
  task :symlink_cap_auth, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/cap_auth.yaml #{release_path}/config/cap_auth.yaml"
  end
end

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
 namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
 end

 