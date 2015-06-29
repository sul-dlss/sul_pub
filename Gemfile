source 'https://rubygems.org'

gem 'rails', '3.2.22'
gem 'bootstrap-sass', '2.0.4'

gem 'mysql2'

gem 'pubmed_search'
gem 'bio'
gem 'grape'
gem 'therubyracer'
gem 'rest-client'
gem 'citeproc-ruby'
gem 'bibtex-ruby'
gem 'yaml_db'
gem 'rsolr'
gem 'rufus-scheduler'
gem 'settingslogic'
gem 'smarter_csv'
gem 'activerecord-import'
gem 'kaminari'
gem 'dotiw'
gem 'high_voltage'
gem 'is_it_working-cbeer', :require => 'is_it_working'
gem 'whenever', :require => false
gem "yajl-ruby", :require => 'yajl'
gem "strong_parameters"
gem "turnout"
gem "parallel"
gem "acts_as_trashable"
gem 'libv8', '>=3.16.14.7'
#gem 'always_verify_ssl_certificates'

group :development, :test do
  gem 'sqlite3'
  gem 'rspec-rails', '~> 3.0'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'spork'
  gem 'debugger', :platforms => :mri_19
  gem 'factory_girl_rails'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel'
end

group :debug do
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
  gem 'pry-debugger', :platforms => :mri_19
end

group :test do
    gem 'capybara'
    gem 'rb-fsevent', '0.9.1', :require => false
    gem 'growl', '1.0.3'
    gem 'faker'
    gem 'simplecov', :require => false
    gem 'vcr'
    gem 'webmock', '1.11'
    gem 'test-unit', require: false
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
 gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
# gem 'debugger'

# Use Squash for exception reporting
gem 'squash_ruby', require: 'squash/ruby'
gem 'squash_rails', require: 'squash/rails'
