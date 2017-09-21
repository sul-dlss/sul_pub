#!/usr/bin/env rake
# If the config/database.yml file does not exist, use the example file so that the config/application can load.
File.exist?('config/database.yml') || FileUtils.copy('config/database.yml.example', 'config/database.yml')

require File.expand_path('../config/application', __FILE__)

Sulbib::Application.load_tasks

task default: [:ci]

desc 'Continuous integration task run on travis'
task ci: [:environment, :rubocop] do
  if Rails.env.test?
    Rake::Task['db:setup'].invoke # not db:migrate, use the dang schema!
    Rake::Task['spec'].invoke
  else
    system 'rake ci RAILS_ENV=test'
  end
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
  namespace :spec do
    desc 'run only data-integration tests against live ScienceWire (excluded by default)'
    RSpec::Core::RakeTask.new('data-integration') { |t| t.rspec_opts = '--tag data-integration' }
  end
rescue LoadError
  puts 'Unable to load RSpec.'
end

desc 'Run rubocop on ruby files in a patch on master'
task :rubocop do
  begin
    require 'rubocop/rake_task'
    RuboCop::RakeTask.new
  rescue LoadError
    puts 'Unable to load RuboCop.'
  end
end

desc 'Run rubocop on ruby files in a patch on master'
task :rubocop_patch do
  if Rails.env.test? || Rails.env.development?
    system "git diff --name-only HEAD..master | grep -E -i 'rake|*.rb|*.erb' | xargs bundle exec rubocop"
  end
end
