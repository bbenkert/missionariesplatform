Rails.application.routes.draw do
  devise_for :users
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  

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
    resources :prayer_requests, only: [:index, :show, :update, :destroy] do
      collection do
        patch :bulk_update
      end
    end
  end
  
  # Organization Admin routes
  scope :organization_admin, as: :organization_admin do
    get '', to: 'organization_admin#dashboard', as: :dashboard
    get :missionaries, to: 'organization_admin#missionaries'
    get :supporters, to: 'organization_admin#supporters'
    get :activity, to: 'organization_admin#activity'
    get :settings, to: 'organization_admin#settings'
    patch :settings, to: 'organization_admin#settings'
  end

  # Missionary routes
  resources :missionaries, only: [:index, :show] do
    resources :updates, except: [:index]
  end

  # Prayer requests
  resources :prayer_requests do
    member do
      post :pray
    end
  end

  # Follow system
  resources :follows, only: [:create, :destroy]

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
