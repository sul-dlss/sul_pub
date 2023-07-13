# frozen_string_literal: true

# ORCID.org utilities
module Orcid
  # @return [SulOrcidClient]
  def self.client
    SulOrcidClient
  end

  def self.logger
    @@logger ||= Logger.new(Settings.ORCID.LOG)
  end

  def self.harvester
    @@harvester ||= Orcid::Harvester.new
  end

  # Extract the ID part from an ORCID ID.
  # For example, 0000-0003-3437-349X from https://sandbox.orcid.org/0000-0003-3437-349X.
  # @param [string] orcidid
  # @return [string] base of ORCID ID
  def self.base_orcidid(orcidid)
    orcidid[-19, 19]
  end

  # Fetch works for a known ID for which we expect to get back publications
  def self.working?
    response = client.fetch_works(orcidid: Settings.ORCID.orcidid_for_check)
    response[:group].size.positive?
  rescue StandardError
    false
  end
end
