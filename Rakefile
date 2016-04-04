#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

task default: [:rubocop, :ci]

# If the config/database.yml file does not exist, use the example file
# so that the config/application can load.
File.exist?('config/database.yml') || FileUtils.copy('config/database.yml.example', 'config/database.yml')

require File.expand_path('../config/application', __FILE__)

Sulbib::Application.load_tasks

desc 'Continuous integration task run on travis'
task ci: [:environment] do
  if Rails.env.test?
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['spec'].invoke
  else
    system 'rake ci RAILS_ENV=test'
  end
end

desc 'Run rubocop on ruby files in a patch on master'
task :rubocop do
  if Rails.env.test? || Rails.env.development?
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new
    rescue LoadError
      puts 'Unable to load RuboCop.'
    end
  end
end

desc 'Run rubocop on ruby files in a patch on master'
task :rubocop_patch do
  if Rails.env.test? || Rails.env.development?
    system "git diff --name-only HEAD..master | grep -E -i 'rake|*.rb|*.erb' | xargs bundle exec rubocop"
  end
end
