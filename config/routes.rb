Rails.application.routes.draw do

  root to: 'default#index'

  # Publication API (for retrieving publications, searching and creating/updating manually entered publications)
  resources :publications, defaults: { format: :json } do
    collection do
      get 'sourcelookup', to: 'publications#sourcelookup'
    end
  end

  # Authorship API (for approving/denying/status updates to any publication)
  resource :authorship, only: [:update, :create], defaults: { format: :json }

  # Harvester API (for triggering manual harvests)
  post '/authors/:cap_profile_id/harvest', to: 'authors#harvest', defaults: { format: :json }

end
