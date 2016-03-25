# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'sul-pub'
set :repo_url, 'git@github.com:sul-dlss/sul-pub.git'
set :ssh_options,   keys: [Capistrano::OneTimeKey.temporary_ssh_private_key_path],
                    forward_agent: true,
                    auth_methods: %w(publickey password)

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/***REMOVED***/sulbib'

# Default branch is the current checkout branch
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push(
  'config/secrets.yml',
  'config/database.yml',
  'config/sciencewire_auth.yaml',
  'config/cap_auth.yaml',
  'config/initializers/squash.rb'
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push(
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'vendor/bundle',
  'public/system'
)

before 'deploy:publishing', 'squash:write_revision'

# set :bundle_audit_ignore, %w(CVE-2015-3226)
