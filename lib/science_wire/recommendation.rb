module ScienceWire
  ##
  # Module of methods for SUL "Recommendation" requests for ScienceWire
  module Recommendation
    ##
    # @param [String] body
    def recommendation(body)
      ScienceWire::Request.new(
        client: self, body: body, path: Settings.SCIENCEWIRE.RECOMMENDATION_PATH
      ).perform
    end
  end
end
