Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api do
    defaults format: :json do
      resources :edit_requests, path: '/edit-requests/:type/:slug', only: [:index, :update]
    end
  end

  resources :collections, path: '/collections(/:type)'
  resources :people, path: '/people(/:role)'
  resources :works, path: '/works(/:type)'

  # Defines the root path route ("/")
  root "home#index"
end
