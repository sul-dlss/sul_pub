ENV['RAILS_ENV'] ||= 'test'

unless ENV['CI']
  require 'pry' # for debugging specs
  require 'byebug'
end

Dir.glob(File.join(__dir__, 'fixtures', '**', '*.rb'), &method(:require)) # load all fixture files

require 'rspec/matchers'
require 'equivalent-xml'
require 'simplecov'

require 'webmock/rspec'
WebMock.enable!

SimpleCov.profiles.define 'sul_pub' do
  add_filter '.gems'
  add_filter '/config/environments/'
  add_filter 'config/initializers/mime_types.rb'
  add_filter 'config/initializers/is_it_working.rb'
  add_filter 'config/initializers/pry.rb'
  add_filter 'db'
  add_filter 'pkg'
  add_filter 'spec'
  add_filter 'vendor'

  # https://github.com/colszowka/simplecov#maximum-coverage-drop
  # Simplecov can detect changes using data from the
  # last rspec run.  Travis will never have a previous
  # dataset for comparison, so it can't fail a travis build.
  maximum_coverage_drop 1
end
SimpleCov.start 'sul_pub'

require File.expand_path('../../config/environment', __FILE__)

ActiveRecord::Migration.maintain_test_schema!

require 'rspec/rails'
require 'factory_bot_rails'

RSpec.configure do |config|
  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: %r{spec/api}
  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: %r{spec/lib}

  config.include FactoryBot::Syntax::Methods

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

RSpec::Matchers.define_negated_matcher :exclude, :include
RSpec::Matchers.define_negated_matcher :not_change, :change

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.allow_http_connections_when_no_cassette = true
  c.hook_into :webmock
  c.default_cassette_options = {
    :record => :new_episodes,  # :once is default
  }
  c.configure_rspec_metadata!
  c.filter_sensitive_data('private_bearer_token') do |interaction|
    auth = interaction.request.headers['Authorization']
    if auth.is_a? Array
      bearer = auth.select { |a| a =~ /bearer/i }.first
      bearer.gsub(/bearer /i, '') if bearer
    end
  end
  c.filter_sensitive_data('Settings.SCIENCEWIRE.HOST') { Settings.SCIENCEWIRE.HOST }
  c.filter_sensitive_data('Settings.SCIENCEWIRE.LICENSE_ID') { Settings.SCIENCEWIRE.LICENSE_ID }
  c.filter_sensitive_data('Settings.PUBMED.API_KEY') { Settings.PUBMED.API_KEY }
  c.filter_sensitive_data('Settings.MAIS.BASE_URL') { Settings.MAIS.BASE_URL }
  c.filter_sensitive_data('Settings.MAIS.CLIENT_ID') { Settings.MAIS.CLIENT_ID }
  c.filter_sensitive_data('Settings.MAIS.CLIENT_SECRET') { Settings.MAIS.CLIENT_SECRET }
  c.filter_sensitive_data('Settings.ORCID.CLIENT_ID') { Settings.ORCID.CLIENT_ID }
  c.filter_sensitive_data('Settings.ORCID.CLIENT_SECRET') { Settings.ORCID.CLIENT_SECRET }

  # WOS Links-AMR filters
  (links_username, links_password) = Base64.decode64(Settings.WOS.AUTH_CODE).split(':', 2)
  c.filter_sensitive_data('links_username') do |interaction|
    links_username if interaction.request.uri.include? Clarivate::LinksClient::LINKS_HOST
  end
  c.filter_sensitive_data('links_password') do |interaction|
    links_password if interaction.request.uri.include? Clarivate::LinksClient::LINKS_HOST
  end

  # CAP API filters
  c.filter_sensitive_data('Settings.CAP.TOKEN_USER:Settings.CAP.TOKEN_PASS') do
    Base64.strict_encode64("#{Settings.CAP.TOKEN_USER}:#{Settings.CAP.TOKEN_PASS}")
  end
  c.filter_sensitive_data('private_access_token') do |interaction|
    if interaction.request.uri.include? Settings.CAP.TOKEN_PATH
      token_match = interaction.response.body.match(/"access_token":"(.*?)"/)
      token_match.captures.first if token_match
    end
  end
  c.filter_sensitive_data('CAP-LicenseID') do |interaction|
    if interaction.request.uri.include? Settings.CAP.AUTHORSHIP_API_PATH
      id_match = interaction.response.body.match(/"californiaPhysicianLicense".*?:.*?"(.*?)"/)
      id_match.captures.first if id_match
    end
  end
  c.filter_sensitive_data('CAP-UniversityID') do |interaction|
    if interaction.request.uri.include? Settings.CAP.AUTHORSHIP_API_PATH
      id_match = interaction.response.body.match(/"universityId".*?:.*?"(.*?)"/)
      id_match.captures.first if id_match
    end
  end
  c.filter_sensitive_data('CAP-UID') do |interaction|
    if interaction.request.uri.include? Settings.CAP.AUTHORSHIP_API_PATH
      id_match = interaction.response.body.match(/"uid".*?:.*?"(.*?)"/)
      id_match.captures.first if id_match
    end
  end

  # WOS API filters
  c.filter_sensitive_data('Settings.WOS.AUTH_CODE') do |interaction|
    Settings.WOS.AUTH_CODE if interaction.request.uri.include? 'WOKMWSAuthenticate'
  end
end

def a_post(path)
  a_request(:post, Settings.SCIENCEWIRE.BASE_URI + path)
end

def a_get(path)
  a_request(:get, Settings.SCIENCEWIRE.BASE_URI + path)
end

def default_institution
  Agent::AuthorInstitution.new(
    Settings.HARVESTER.INSTITUTION.name,
    Agent::AuthorAddress.new(Settings.HARVESTER.INSTITUTION.address.to_hash)
  )
end

require_relative 'lib/web_of_science/wsdl'
WebOfScience::WSDL.fetch
