# capistrano reads this file AFTER config/deploy.rb

HOST = 'sul-pub-dev.stanford.edu'
set :user, 'pub'
set :home_directory, `ssh #{fetch(:user)}@#{HOST} 'echo $HOME'`.chomp

# Override the default :deploy_to in config/deploy.rb
set :deploy_to, "#{fetch(:home_directory)}/#{fetch(:application)}"

server HOST, user: fetch(:user), roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'development'

# This is a development box, do not exclude development gems.
set :bundle_without, 'test'
