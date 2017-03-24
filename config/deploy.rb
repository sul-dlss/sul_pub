# config valid only for current version of Capistrano
lock '3.8.0'

set :application, 'sul-pub'
set :user, 'pub'
set :repo_url, "git@github.com:sul-dlss/sul_pub.git"
set :ssh_options,   keys: [Capistrano::OneTimeKey.temporary_ssh_private_key_path],
                    forward_agent: true,
                    auth_methods: %w(publickey password)

set :home_directory, "/opt/app/#{fetch(:user)}"
set :deploy_to, "#{fetch(:home_directory)}/#{fetch(:application)}"

# Default branch is the current checkout branch
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push(
  'config/secrets.yml',
  'config/database.yml',
  'config/honeybadger.yml'
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push(
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'vendor/bundle',
  'public/system',
  'config/settings'
)

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
