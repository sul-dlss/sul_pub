require 'api'

Sulbib::Application.routes.draw do

  mount SulBib::API => "/publications"
  mount SulBib::API_samples => "/samples"
  #mount SulBib::API_authors => "/authors"

  root to: 'static_pages#api'

  get "static_pages/home"
  get "static_pages/api"
  get 'static_pages/pubapi'
  get 'static_pages/pubsapi'
  get 'static_pages/queryapi'
  get 'static_pages/pollapi'
  get 'static_pages/bibtex'
  #resources :profiles

 # get "people/index"
  #get "people/edit"
  #get "people/show"
  #get "people/new"

  #get "science_wire_records/index"
  #get "science_wire_records/show"
  #get "science_wire_records/populate"
  #post "science_wire_records/search"

  #get "pub_med_records/index"
  #get "pub_med_records/show"
  #get "pub_med_records/populate"
  #post "pub_med_records/search"
  
  # resources :publications
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
