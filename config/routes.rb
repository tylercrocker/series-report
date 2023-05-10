require 'sidekiq/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  # end

  defaults format: :json do
    resources :edit_requests, path: '/edit-requests(/:editable_type/:editable_slug)', only: [:index, :create, :update]
  end

  resources :collections, path: '/collections(/:type)', param: :slug, only: [:index, :show]
  resources :people, param: :slug, only: [:index, :show]
  resources :works, path: '/works(/:type)', param: :slug, only: [:index, :show]

  # Defines the root path route ("/")
  root "home#index"
end
