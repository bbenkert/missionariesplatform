require 'rails_helper'

RSpec.describe 'Routes', type: :routing do
  describe 'Authentication routes' do
    it 'routes GET /sign_in to sessions#new' do
      expect(get: '/sign_in').to route_to('sessions#new')
    end

    it 'routes POST /sign_in to sessions#create' do
      expect(post: '/sign_in').to route_to('sessions#create')
    end

    it 'routes DELETE /sign_out to sessions#destroy' do
      expect(delete: '/sign_out').to route_to('sessions#destroy')
    end

    it 'routes GET /sign_up to registrations#new' do
      expect(get: '/sign_up').to route_to('registrations#new')
    end

    it 'routes POST /sign_up to registrations#create' do
      expect(post: '/sign_up').to route_to('registrations#create')
    end
  end

  describe 'Password reset routes' do
    it 'routes GET /password/reset to passwords#new' do
      expect(get: '/password/reset').to route_to('passwords#new')
    end

    it 'routes POST /password/reset to passwords#create' do
      expect(post: '/password/reset').to route_to('passwords#create')
    end

    it 'routes GET /password/reset/edit to passwords#edit' do
      expect(get: '/password/reset/edit').to route_to('passwords#edit')
    end

    it 'routes PATCH /password/reset/edit to passwords#update' do
      expect(patch: '/password/reset/edit').to route_to('passwords#update')
    end
  end

  describe 'Root route' do
    it 'routes GET / to home#index' do
      expect(get: '/').to route_to('home#index')
    end
  end

  describe 'Admin routes' do
    it 'routes GET /admin to admin/dashboard#index' do
      expect(get: '/admin').to route_to('admin/dashboard#index')
    end

    it 'routes admin missionaries resources' do
      expect(get: '/admin/missionaries').to route_to('admin/missionaries#index')
      expect(get: '/admin/missionaries/1').to route_to('admin/missionaries#show', id: '1')
      expect(patch: '/admin/missionaries/1').to route_to('admin/missionaries#update', id: '1')
      expect(patch: '/admin/missionaries/1/approve').to route_to('admin/missionaries#approve', id: '1')
      expect(patch: '/admin/missionaries/1/flag_for_review').to route_to('admin/missionaries#flag_for_review', id: '1')
      expect(patch: '/admin/missionaries/1/toggle_visibility').to route_to('admin/missionaries#toggle_visibility', id: '1')
    end

    it 'routes admin users resources' do
      expect(get: '/admin/users').to route_to('admin/users#index')
      expect(get: '/admin/users/1').to route_to('admin/users#show', id: '1')
      expect(patch: '/admin/users/1').to route_to('admin/users#update', id: '1')
    end

    it 'routes admin messages resources' do
      expect(get: '/admin/messages').to route_to('admin/messages#index')
      expect(get: '/admin/messages/1').to route_to('admin/messages#show', id: '1')
      expect(delete: '/admin/messages/1').to route_to('admin/messages#destroy', id: '1')
    end
  end

  describe 'Missionary routes' do
    it 'routes missionaries resources' do
      expect(get: '/missionaries').to route_to('missionaries#index')
      expect(get: '/missionaries/1').to route_to('missionaries#show', id: '1')
    end

    it 'routes follow/unfollow actions' do
      expect(post: '/missionaries/1/follow').to route_to('missionaries#follow', id: '1')
      expect(delete: '/missionaries/1/unfollow').to route_to('missionaries#unfollow', id: '1')
    end

    it 'routes missionary updates' do
      expect(get: '/missionaries/1/updates/new').to route_to('updates#new', missionary_id: '1')
      expect(post: '/missionaries/1/updates').to route_to('updates#create', missionary_id: '1')
      expect(get: '/missionaries/1/updates/2').to route_to('updates#show', missionary_id: '1', id: '2')
      expect(get: '/missionaries/1/updates/2/edit').to route_to('updates#edit', missionary_id: '1', id: '2')
      expect(patch: '/missionaries/1/updates/2').to route_to('updates#update', missionary_id: '1', id: '2')
      expect(delete: '/missionaries/1/updates/2').to route_to('updates#destroy', missionary_id: '1', id: '2')
    end
  end

  describe 'User routes' do
    it 'routes GET /dashboard to dashboard#index' do
      expect(get: '/dashboard').to route_to('dashboard#index')
    end

    it 'routes profile resource' do
      expect(get: '/profile').to route_to('profiles#show')
      expect(get: '/profile/edit').to route_to('profiles#edit')
      expect(patch: '/profile').to route_to('profiles#update')
    end
  end

  describe 'Messaging routes' do
    it 'routes conversations resources' do
      expect(get: '/conversations').to route_to('conversations#index')
      expect(get: '/conversations/1').to route_to('conversations#show', id: '1')
      expect(post: '/conversations').to route_to('conversations#create')
    end

    it 'routes conversation messages' do
      expect(post: '/conversations/1/messages').to route_to('messages#create', conversation_id: '1')
    end

    it 'routes conversation actions' do
      expect(patch: '/conversations/1/block').to route_to('conversations#block', id: '1')
      expect(post: '/conversations/1/report').to route_to('conversations#report', id: '1')
    end
  end

  describe 'API routes' do
    it 'routes API v1 missionaries' do
      expect(get: '/api/v1/missionaries').to route_to('api/v1/missionaries#index')
      expect(get: '/api/v1/missionaries/1').to route_to('api/v1/missionaries#show', id: '1')
    end

    it 'routes API v1 updates' do
      expect(get: '/api/v1/updates').to route_to('api/v1/updates#index')
      expect(get: '/api/v1/updates/1').to route_to('api/v1/updates#show', id: '1')
    end

    it 'routes API v1 stats' do
      expect(get: '/api/v1/stats').to route_to('api/v1/stats#index')
    end
  end

  describe 'Health check' do
    it 'routes GET /up to rails/health#show' do
      expect(get: '/up').to route_to('rails/health#show')
    end
  end

  describe 'Sidekiq Web UI' do
    it 'mounts Sidekiq::Web at /sidekiq' do
      # This is harder to test directly, but we can verify the route exists
      expect(Rails.application.routes.url_helpers.sidekiq_web_path).to be_present
    end
  end
end
