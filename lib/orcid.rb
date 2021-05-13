# frozen_string_literal: true

# ORCID.org utilities
module Orcid
  # @return [Orcid::Client]
  def self.client
    Orcid::Client.new
  end
end
