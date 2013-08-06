require 'sul_bib/year_check'
require 'sul_bib/authz'
require 'sul_bib/authorship_api'
require 'sul_bib/publications_api'

module SulBib
  class API < Grape::API
    group (:authorship) { mount SulBib::AuthorshipAPI }
    group (:publications) { mount SulBib::PublicationsAPI }
  end

end