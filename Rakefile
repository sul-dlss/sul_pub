#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

task default: [:ci, :rubocop]

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
