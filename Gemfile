source 'https://rubygems.org'

gem 'rails', '~> 6.0', '< 6.1'
# pinning to 6.0.x as the paper_trail gem is not currently compatible with activerecord 6.1 as of Jan 5 2021
# an update appears to be in the works...see https://github.com/paper-trail-gem/paper_trail

# Use sass-powered bootstrap
gem 'bootstrap-sass', '~> 3.4.1'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.1'

# pinning myql2 since 0.5.3 is currently not compatible with our version of CentOS and Ruby (as of Apr 2020)
gem 'mysql2', '~> 0.5', '< 0.5.3'

gem 'nokogiri', '>= 1.7.1'

gem 'activerecord-import'
gem 'bibtex-ruby'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'citeproc-ruby', '~> 1.1'
gem 'unicode' # CiteProc requires the `unicode_utils` or `unicode` Gem on Ruby 2.3
gem 'config'

# See https://github.com/sul-dlss/sul_pub/issues/1019 before updating:
gem 'csl-styles', '1.0.1.8'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'dotiw'
gem 'faraday'
gem 'htmlentities', '~> 4.3'
gem 'httpclient', '~> 2.8'
# Altmetric utilities related to the extraction, validation and normalization of various scholarly identifiers
gem 'identifiers', '~> 0.12'
# To use Jbuilder templates for JSON
gem 'jbuilder'
gem 'jquery-rails'
gem 'json_schemer'
gem 'kaminari'
gem 'okcomputer' # for monitoring
gem 'oauth2'
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

gem 'honeybadger', '~> 4.2'
gem 'retina_tag'

group :development, :test do
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rspec'
  gem 'rspec-rails'
end

group :development do
  gem 'byebug'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'pry-doc'
  gem 'ruby-prof'
  gem 'thin' # app server
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
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
  gem 'capistrano3-delayed-job', '~> 1.0'
end
