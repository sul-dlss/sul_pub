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

  # Simplecov can detect changes using data from the
  # last rspec run.  Travis will never have a previous
  # dataset for comparison, so it can't fail a travis build.
  maximum_coverage_drop 0.1
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
VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {
    :record => :new_episodes,  # :once is default
  }
  c.configure_rspec_metadata!
  c.filter_sensitive_data('Settings.CAP.TOKEN_USER:Settings.CAP.TOKEN_PASS@Settings.CAP.TOKEN_URI') do
    "#{Settings.CAP.TOKEN_USER}:#{Settings.CAP.TOKEN_PASS}@#{Settings.CAP.TOKEN_URI}"
  end
  c.filter_sensitive_data('private_access_token') do |interaction|
    if interaction.request.body == "grant_type=client_credentials"
      regex = %r("access_token":"(.*?)")
      regex.match(interaction.response.body).captures.first
    end
  end
  c.filter_sensitive_data('private_bearer_token') do |interaction|
    auth = interaction.request.headers['Authorization']
    if auth.kind_of? Array
      bearer = auth.select {|a| a =~ /bearer/i }.first
      bearer.gsub(/bearer /i, '') if bearer
    end
  end
  c.filter_sensitive_data('Settings.SCIENCEWIRE.HOST') { Settings.SCIENCEWIRE.HOST }
  c.filter_sensitive_data('Settings.SCIENCEWIRE.LICENSE_ID') { Settings.SCIENCEWIRE.LICENSE_ID }
end
