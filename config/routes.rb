require 'api'

Sulbib::Application.routes.draw do

  mount SulBib::API => "/publications"
  mount SulBib::API_samples => "/samples"
  mount SulBib::API_authorship => "/authorship"

  root to: 'static_pages#api'

  get "static_pages/home"
  get "static_pages/api"
  get 'static_pages/pubapi'
  get 'static_pages/pubsapi'
  get 'static_pages/queryapi'
  get 'static_pages/pollapi'
  get 'static_pages/bibtex'

  get 'schemas/book'
  get 'schemas/article'
  get 'schemas/inproceedings'
 
end
