require "sidekiq/web"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  mount Sidekiq::Web => "/sidekiq"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # API Routes
  namespace :api do
    namespace :v1 do
      resources :products, only: [ :index, :show ]
      resource :shopping_basket, only: [ :show ] do
        resources :products, only: [ :create ], controller: "shopping_baskets/shopping_basket_products"
        resource :checkout, only: [ :create ], controller: "shopping_baskets/checkouts"
      end
    end

    namespace :v2 do
      resources :products, only: [ :index, :show ]
    end
  end

  # Health check endpoint
  get "health", to: proc { [ 200, {}, [ "OK" ] ] }
end
