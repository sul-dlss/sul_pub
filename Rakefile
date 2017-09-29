#!/usr/bin/env rake
# If the config/database.yml file does not exist, use the example file so that the config/application can load.
File.exist?('config/database.yml') || FileUtils.copy('config/database.yml.example', 'config/database.yml')

require File.expand_path('../config/application', __FILE__)

Sulbib::Application.load_tasks

task default: [:ci]

desc 'Continuous integration task run on travis'
task ci: [:rubocop, :spec]

begin
  require 'rspec/core/rake_task'

  desc 'Run only data-integration tests against live ScienceWire (excluded by default)'
  RSpec::Core::RakeTask.new('spec_with_data_integration') { |t| t.rspec_opts = '--tag data-integration' }
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
