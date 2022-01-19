# frozen_string_literal: true

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.allow_http_connections_when_no_cassette = true
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :new_episodes # :once is default
  }
  c.configure_rspec_metadata!
  c.filter_sensitive_data('private_bearer_token') do |interaction|
    auth = interaction.request.headers['Authorization']
    if auth.is_a? Array
      bearer = auth.grep(/bearer/i).first
      bearer&.gsub(/bearer /i, '')
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

  # ORCID API filters
  c.filter_sensitive_data('refresh_token') do |interaction|
    if interaction.request.uri.include? Settings.ORCID.BASE_AUTH_URL
      token_match = interaction.response.body.match(/"refresh_token":"(.*?)"/)
      token_match&.captures&.first
    end
  end

  # CAP API filters
  c.filter_sensitive_data('Settings.CAP.TOKEN_USER:Settings.CAP.TOKEN_PASS') do
    Base64.strict_encode64("#{Settings.CAP.TOKEN_USER}:#{Settings.CAP.TOKEN_PASS}")
  end
  c.filter_sensitive_data('private_access_token') do |interaction|
    if interaction.request.uri.include? Settings.CAP.TOKEN_PATH
      token_match = interaction.response.body.match(/"access_token":"(.*?)"/)
      token_match&.captures&.first
    end
  end
  c.filter_sensitive_data('CAP-LicenseID') do |interaction|
    if interaction.request.uri.include? Settings.CAP.AUTHORSHIP_API_PATH
      id_match = interaction.response.body.match(/"californiaPhysicianLicense".*?:.*?"(.*?)"/)
      id_match&.captures&.first
    end
  end
  c.filter_sensitive_data('CAP-UniversityID') do |interaction|
    if interaction.request.uri.include? Settings.CAP.AUTHORSHIP_API_PATH
      id_match = interaction.response.body.match(/"universityId".*?:.*?"(.*?)"/)
      id_match&.captures&.first
    end
  end
  c.filter_sensitive_data('CAP-UID') do |interaction|
    if interaction.request.uri.include? Settings.CAP.AUTHORSHIP_API_PATH
      id_match = interaction.response.body.match(/"uid".*?:.*?"(.*?)"/)
      id_match&.captures&.first
    end
  end

  # WOS API filters
  c.filter_sensitive_data('Settings.WOS.AUTH_CODE') do |interaction|
    Settings.WOS.AUTH_CODE if interaction.request.uri.include? 'WOKMWSAuthenticate'
  end
end
