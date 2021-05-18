# frozen_string_literal: true

# ORCID.org utilities
module Orcid
  # @return [Orcid::Client]
  def self.client
    Orcid::Client.new
  end

  # Fetch works for a known ID for which we expect to get back publications
  def self.working?
    response = client.fetch_works(Settings.ORCID.orcidid_for_check)
    response[:group].size.positive?
  rescue StandardError
    false
  end
end
