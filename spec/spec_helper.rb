# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require 'pry'  # for debugging specs

require 'simplecov'
require 'coveralls'
SimpleCov.profiles.define 'sul-pub' do
  add_filter '.gems'
  add_filter '/config/environments/'
  add_filter 'config/initializers/mime_types.rb'
  add_filter 'config/initializers/is_it_working.rb'
  add_filter 'config/initializers/pry.rb'
  add_filter 'pkg'
  add_filter 'spec'
  add_filter 'vendor'
end
SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start 'sul-pub'

require File.expand_path('../../config/environment', __FILE__)

ActiveRecord::Migration.maintain_test_schema!

require 'rspec/rails'
require 'factory_girl_rails'

RSpec.configure do |config|
  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: %r{spec/api}
  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: %r{spec/lib}

  config.include FactoryGirl::Syntax::Methods

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end

require 'vcr'
cassette_ttl = 7 * 24 * 60 * 60  # 7 days, in seconds
VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
  c.default_cassette_options = {
    :record => :new_episodes,  # :once is default
    :re_record_interval => cassette_ttl
  }
  c.configure_rspec_metadata!
end
