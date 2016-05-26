require 'sul_bib/year_check'
require 'sul_bib/authorship_api'
require 'sul_bib/publications_api'

module SulBib
  class API < Grape::API
    logger Rails.logger

    before do
      error!('Unauthorized', 401) if env['HTTP_CAPKEY'].nil?
      error!('Forbidden', 403) unless env['HTTP_CAPKEY'] == Settings.API_KEY
    end

    helpers do
      def logger
        API.logger
      end
    end

    group(:authorship) { mount SulBib::AuthorshipAPI }
    group(:publications) { mount SulBib::PublicationsAPI }
  end
end
