source 'https://rubygems.org'

gem 'rails', '~> 7.1.3' # allow rails to be updated to 7.1.x (will be needed for sqlite 2 to work)

gem 'nokogiri', '>= 1.7.1'

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
gem 'htmlentities', '~> 4.3'
gem 'httpclient', '~> 2.8'
gem 'identifiers', '~> 0.12' # Altmetric utilities related to the extraction, validation and normalization of various scholarly identifiers
gem 'jbuilder' # To use Jbuilder templates for JSON
gem 'json_schemer'
gem 'kaminari'
gem 'mais_orcid_client'
gem 'okcomputer' # for monitoring
gem 'oauth2'
gem 'paper_trail'
gem 'parallel'
gem 'pry' # make it possible to use pry for IRB
gem 'rake'
gem 'StreetAddress', '~> 1.0', '>= 1.0.6'
gem 'sul_orcid_client'
gem 'whenever', require: false
gem 'yaml_db'
gem 'hashie' # this used to be part of grape, but we still need it since we believe pub_hashes may still be seralized in the database this way 9/10/2018

gem 'honeybadger'
gem 'retina_tag'

group :development, :test do
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'sqlite3', '~> 1.7' # sqlite3 2.0.0 is not currently compatible with Rails 7.1; unpin when new rails release: https://github.com/rails/rails/pull/51636
end

group :development do
  gem 'byebug'
  gem 'listen', '~> 3.7'
  gem 'pry-doc'
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

group :production do
  # mysql 0.5.3 is required for ruby 3 and is supported on latest OS in use: Oracle Linux (as of Jan 2022)
  gem 'mysql2', '>= 0.5.3'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shell'
  gem 'dlss-capistrano'
end
