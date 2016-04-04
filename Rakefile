#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

task default: [:rubocop, :ci, 'vcr:sanitize']

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

namespace :vcr do
  desc 'List all VCR cassettes'
  task :cassettes do
    Dir.glob("fixtures/vcr_cassettes/**/*.yml") { |f| puts f }
  end

  desc 'Remove private credentials from VCR cassettes'
  task :sanitize do
    puts "VCR SANITIZE: sanitizing private credentials in the vcr cassettes"
    # Read public values from `config/settings.yml`.
    public_settings = YAML.load(ERB.new(File.read("#{Rails.root}/config/settings.yml")).result)
    # Sanitize values for the ScienceWire licence.
    public_license = public_settings['SCIENCEWIRE']['LICENSE_ID']
    config_license = Settings.SCIENCEWIRE.LICENSE_ID
    # Sanitize values for the CAP authorization credentials.
    cap_token_user = public_settings['CAP']['TOKEN_USER']
    cap_token_pass = public_settings['CAP']['TOKEN_PASS']
    cap_token_uri = public_settings['CAP']['TOKEN_URI']
    public_cap_authz = "#{cap_token_user}:#{cap_token_pass}@#{cap_token_uri}"
    cap_token_user = Settings.CAP.TOKEN_USER
    cap_token_pass = Settings.CAP.TOKEN_PASS
    cap_token_uri = Settings.CAP.TOKEN_URI
    config_cap_authz = "#{cap_token_user}:#{cap_token_pass}@#{cap_token_uri}"
    # Create and apply a mapping of private to public values.
    sanitize_map = {
      config_license => public_license,
      config_cap_authz => public_cap_authz,
    }
    sanitize_map.each_pair do |private_value, public_value|
      next if private_value == public_value
      Dir.glob("fixtures/vcr_cassettes/**/*.yml") do |file_name|
        text = File.read(file_name)
        text.include?(private_value) && File.write(file_name, text.gsub(private_value, public_value))
      end
    end
  end
end
