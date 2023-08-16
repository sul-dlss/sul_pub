# frozen_string_literal: true

# UIT MAIS ORCID User API utilities
module Mais
  # @return [MaisOrcidClient]
  def self.client
    MaisOrcidClient
  end

  def self.logger
    Logger.new(Settings.MAIS.LOG)
  end

  # Retrieve a single ORCID user record.
  def self.working?
    orcid_users = client.fetch_orcid_users(limit: 1)
    orcid_users.size == 1
  rescue StandardError => e
    Honeybadger.notify(e, context: { message: 'OK Computer debug: Mais client check failed' })
    false
  end
end
