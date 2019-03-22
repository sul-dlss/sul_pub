require 'sul_bib/api'

Rails.application.routes.draw do
  if Rails.env.development?
    mount RailsDb::Engine => '/rails/db', :as => 'rails_db'
  end

  get '/publications' => 'publications#index'
  get '/publications/sourcelookup' => 'publications#sourcelookup'

  ##
  # Endpoint for Author harvester
  post '/authors/:cap_profile_id/harvest', to: 'authors#harvest', defaults: { format: :json }

  mount SulBib::API, at: '', as: 'api'
end
