Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  get "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  delete "sign_out", to: "sessions#destroy"
  
  get "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"

  # Password reset routes
  get "password/reset", to: "passwords#new"
  post "password/reset", to: "passwords#create"
  get "password/reset/edit", to: "passwords#edit"
  patch "password/reset/edit", to: "passwords#update"

  # Root route
  root "home#index"

  # Admin routes
  namespace :admin do
    root "dashboard#index"
    resources :missionaries, only: [:index, :show, :update] do
      member do
        patch :approve
        patch :flag_for_review
        patch :toggle_visibility
      end
    end
    resources :users, only: [:index, :show, :update]
    resources :messages, only: [:index, :show, :destroy]
  end

  # Missionary routes
  resources :missionaries, only: [:index, :show] do
    member do
      post :follow
      delete :unfollow
    end
    resources :updates, except: [:index]
  end

  # User dashboard and profile
  get "dashboard", to: "dashboard#index"
  resource :profile, only: [:show, :edit, :update]

  # Messaging system
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]
    member do
      patch :block
      post :report
    end
  end

  # API routes for AJAX requests
  namespace :api do
    namespace :v1 do
      resources :missionaries, only: [:index, :show]
      resources :updates, only: [:index, :show]
      get "stats", to: "stats#index"
    end
  end

  # Sidekiq Web UI (for admins only)
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
