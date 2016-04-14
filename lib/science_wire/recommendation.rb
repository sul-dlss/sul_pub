module ScienceWire
  ##
  # Module of methods for SUL "Recommendation" requests for ScienceWire
  module Recommendation
    ##
    # @param [String] body
    def recommendation(body)
      ScienceWire::Request.new(
        client: self,
        request_method: :post,
        body: body,
        path: Settings.SCIENCEWIRE.RECOMMENDATION_PATH,
        timeout_period: 500
      ).perform
    end
  end
end
