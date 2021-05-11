#!/usr/bin/env rake
# frozen_string_literal: true

# If the config/database.yml file does not exist, use the example file so that the config/application can load.
File.exist?('config/database.yml') || FileUtils.copy('config/database.yml.example', 'config/database.yml')

require File.expand_path('../config/application', __FILE__)

Sulbib::Application.load_tasks

task default: [:ci]

desc 'Continuous integration task run on travis'
task ci: %i[rubocop spec]

desc 'Run rubocop on ruby files in a patch on master'
task :rubocop do
  begin
    require 'rubocop/rake_task'
    RuboCop::RakeTask.new
  rescue LoadError
    puts 'Unable to load RuboCop.'
  end
end
