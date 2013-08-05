require 'api'

Sulbib::Application.routes.draw do

  mount SulBib::API => "/publications"
  mount SulBib::AuthorshipAPI => "/authorship"

  get "/*id" => 'high_voltage/pages#show', :as => :page, :format => false
  root :to => 'high_voltage/pages#show', id: 'api'

end
