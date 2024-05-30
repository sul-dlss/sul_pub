# see https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment
set :application, 'sul-pub'
set :repo_url, "git@github.com:sul-dlss/sul_pub.git"
# set :ssh_options,   keys: [Capistrano::OneTimeKey.temporary_ssh_private_key_path],
#                     forward_agent: true,
#                     auth_methods: %w(publickey password)

set :deploy_to, "/opt/app/pub/#{fetch(:application)}"

# Default branch is :main
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

# honeybadger_env otherwise defaults to rails_env
# we want prod rather than production
set :honeybadger_env, fetch(:stage)

before 'deploy:restart', 'shared_configs:update'
