source 'https://rubygems.org'

gem 'rails', '~> 4.2.5'
gem 'grape'

# Use sass-powered bootstrap
gem 'bootstrap-sass', '~> 3.3.4'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# JS Runtime. See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer'

gem 'mysql2'

gem 'activerecord-import'
# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'
gem 'bibtex-ruby'
gem 'bio'
gem 'citeproc-ruby', '0.0.6'
gem 'dotiw'
gem 'high_voltage'
gem 'is_it_working-cbeer', require: 'is_it_working'
# To use Jbuilder templates for JSON
gem 'jbuilder'
gem 'jquery-rails'
gem 'kaminari'
gem 'libv8'
gem 'turnout'
gem 'parallel'
gem 'paper_trail'
gem 'pry-rails'
gem 'pubmed_search'
gem 'rest-client'
gem 'settingslogic'
gem 'whenever', require: false
gem 'yaml_db'

# Use Squash for exception reporting
gem 'squash_ruby', require: 'squash/ruby'
gem 'squash_rails', require: 'squash/rails'
gem 'retina_tag'


group :development, :test do
  gem 'rspec-rails', '~> 3.0'
  gem 'factory_girl_rails'
  gem 'pry-doc'
  # Administrative UI for MySQL DB
  # https://github.com/igorkasyanchuk/rails_db
  gem 'rails_db'
  gem 'axlsx_rails'
  gem 'thin' # app server
end

group :test do
  gem 'capybara'
  gem 'coveralls', require: false
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel'
end
