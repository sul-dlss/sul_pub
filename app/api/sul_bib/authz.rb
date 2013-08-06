module SulBib
  module Authz
    extend ActiveSupport::Concern

    included do
      before do
        error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == SulBib::API_KEY
      end
    end

  end
end