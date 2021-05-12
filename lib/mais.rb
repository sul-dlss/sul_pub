# frozen_string_literal: true

# UIT MAIS ORCID User API utilities
module Mais
  # @return [Mais::Client]
  def self.client
    Mais::Client.new
  end

  def self.logger
    Logger.new(Settings.MAIS.LOG)
  end

  # Retrieve a single ORCID user record.
  def self.working?
    orcid_users = client.fetch_orcid_users(limit: 1)
    orcid_users.size == 1
  rescue StandardError
    false
  end
end
