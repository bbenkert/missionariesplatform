Rails.application.routes.draw do
  devise_for :users
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "rails/health#show"

  # Sidekiq Web UI (admin only)
  if Rails.env.production?
    begin
      require 'sidekiq/web'
      mount Sidekiq::Web => '/sidekiq', constraints: lambda { |request|
        # Only allow admin users to access Sidekiq web interface
        user = User.find_by(id: request.session[:user_id]) if request.session[:user_id]
        user&.admin?
      }
    rescue LoadError
      Rails.logger.warn "Sidekiq not available - skipping web UI mount"
    end
  else
    begin
      require 'sidekiq/web'
      mount Sidekiq::Web => '/sidekiq'
    rescue LoadError
      Rails.logger.warn "Sidekiq not available - skipping web UI mount"
    end
  end

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
    resources :users, only: [:index, :show, :edit, :update] do
      collection do
        patch :bulk_actions
      end
      member do
        patch :approve_missionary
        patch :suspend
        patch :activate
      end
    end
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
    resources :updates
  end

  # Prayer requests
  resources :prayer_requests do
    member do
      post :pray
    end
  end

  # Follow system
  post "follows", to: "follows#create"
  delete "follows", to: "follows#destroy"

  # User dashboard and profile
  get "dashboard", to: "dashboard#index"
  get "dashboard/supporter", to: "dashboard#supporter", as: :dashboard_supporter
  resource :profile, only: [:show, :edit, :update]

  # Messaging system
  resources :conversations, only: [:index, :show, :new, :create] do
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

  # Sidekiq Web UI disabled - using async queue adapter
  # require 'sidekiq/web'
  # mount Sidekiq::Web => '/sidekiq'
end
