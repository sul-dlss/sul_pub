require 'sul_bib/api'

Sulbib::Application.routes.draw do
  if Rails.env.development?
    mount RailsDb::Engine => '/rails/db', :as => 'rails_db'
  end

  get '/publications' => 'publications#index'
  get '/publications/sourcelookup' => 'publications#sourcelookup'

  mount SulBib::API, at: '', as: 'api'
end
