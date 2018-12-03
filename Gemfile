source 'https://rubygems.org'

gem 'grape', '~> 1.2'
gem 'rails', '~> 4.2.10'

# Use sass-powered bootstrap
gem 'bootstrap-sass', '~> 3.3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.1'

gem 'mysql2', '~> 0.4.10'

gem 'nokogiri', '>= 1.7.1'

gem 'activerecord-import'
gem 'bibtex-ruby'
gem 'citeproc-ruby', '~> 1.1'
gem 'unicode' # CiteProc requires the `unicode_utils` or `unicode` Gem on Ruby 2.3
gem 'config'
gem 'csl-styles', '~> 1.0'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'dotiw'
gem 'faraday'
gem 'high_voltage'
gem 'htmlentities', '~> 4.3'
gem 'httpclient', '~> 2.8'
# Altmetric utilities related to the extraction, validation and normalization of various scholarly identifiers
gem 'identifiers', '~> 0.12'
# To use Jbuilder templates for JSON
gem 'jbuilder'
gem 'jquery-rails'
gem 'kaminari'
gem 'okcomputer' # for monitoring
gem 'paper_trail'
gem 'parallel'
gem 'pry-rails'
gem 'rake'
gem 'savon', '~> 2.12'
gem 'simple_form'
gem 'StreetAddress', '~> 1.0', '>= 1.0.6'
gem 'whenever', require: false
gem 'yaml_db'
gem 'hashie' # this used to be part of grape, but we still need it since we believe pub_hashes may still be seralized in the database this way 9/10/2018

# -------------------
gem 'honeybadger', '~> 4.1'
gem 'retina_tag'

group :development, :test do
  gem 'dlss_cops' # includes rubocop
  gem 'rails_db'
  gem 'rspec'
  gem 'rspec-rails', '~> 3.8'
end

group :development do
  gem 'byebug'
  gem 'pry-doc'
  gem 'ruby-prof'
  gem 'thin' # app server
end

group :test do
  gem 'capybara'
  gem 'coveralls', '~> 0.8', require: false
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'simplecov', '~> 0.13', require: false
  gem 'vcr'
  gem 'webmock'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shell'
  gem 'dlss-capistrano'
  gem 'capistrano3-delayed-job', '~> 1.0'
end
