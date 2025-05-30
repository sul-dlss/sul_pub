source 'https://rubygems.org'

gem 'activerecord-import'
gem 'bibtex-ruby'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'citeproc-ruby', '~> 1.1'
gem 'config'
gem 'csl-styles', '1.0.1.8' # See https://github.com/sul-dlss/sul_pub/issues/1019 before updating
gem 'csv'
gem 'daemons'
gem 'dotiw'
gem 'faraday'
gem 'faraday-httpclient'
gem 'faraday-retry'
gem 'hashie' # this used to be part of grape, but we still need it since we believe pub_hashes may still be seralized in the database this way 9/10/2018
gem 'honeybadger'
gem 'htmlentities', '~> 4.3'
gem 'httpclient', '~> 2.8'
gem 'identifiers', '~> 0.12' # Altmetric utilities related to the extraction, validation and normalization of various scholarly identifiers
gem 'jbuilder' # To use Jbuilder templates for JSON
gem 'json_schemer'
gem 'kaminari'
gem 'mais_orcid_client', '>= 1.0'
gem 'mutex_m'  # needed because httpclient depends on it and is unmaintained
gem 'nokogiri', '>= 1.7.1'
gem 'oauth2'
gem 'okcomputer' # for monitoring
gem 'paper_trail'
gem 'parallel'
gem 'pg'
gem 'pry' # make it possible to use pry for IRB
gem 'rails', '~> 8.0.0'
gem 'rake'
gem 'retina_tag'
gem 'StreetAddress', '~> 1.0', '>= 1.0.6'
gem 'sul_orcid_client'
gem 'whenever', require: false
gem 'yaml_db'

group :development, :test do
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
  gem 'rspec'
  gem 'rspec_junit_formatter' # used by CircleCI
  gem 'rspec-rails'
end

group :development do
  gem 'byebug'
  gem 'listen', '~> 3.7'
  gem 'ruby-prof'
  gem 'thin' # app server
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails', '~> 6.2.0' # unpin when https://github.com/thoughtbot/factory_bot_rails/pull/432 or issue/433 is in a release
  gem 'rails-controller-testing'
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
end
