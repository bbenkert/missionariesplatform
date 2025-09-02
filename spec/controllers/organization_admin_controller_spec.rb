require 'rails_helper'

RSpec.describe OrganizationAdminController, type: :controller do
  include Devise::Test::ControllerHelpers
  
  let(:organization) { FactoryBot.create(:organization) }
  let(:organization_admin) { FactoryBot.create(:user, :organization_admin, organization: organization) }
  let(:supporter) { FactoryBot.create(:user, :supporter) }
  
  before do
    sign_in organization_admin
  end
  
  describe 'GET #dashboard' do
    it 'returns success for organization admin' do
      get :dashboard
      expect(response).to have_http_status(:success)
    end
    
    it 'loads organization statistics' do
      # Create test data
      missionary = FactoryBot.create(:user, :missionary, organization: organization)
      FactoryBot.create(:missionary_profile, user: missionary, organization: organization)
      Follow.create!(user: supporter, followable: organization)
      
      get :dashboard
      
      expect(assigns(:stats)).to include(
        :missionaries,
        :supporters,
        :total_updates,
        :prayer_requests
      )
    end
    
    it 'calculates monthly activity data' do
      get :dashboard
      
      expect(assigns(:monthly_activity)).to be_an(Array)
      expect(assigns(:monthly_activity).first).to include(:month, :updates, :new_supporters)
    end
  end
  
  describe 'GET #missionaries' do
    let!(:missionary) { FactoryBot.create(:user, :missionary, organization: organization) }
    
    before do
      FactoryBot.create(:missionary_profile, user: missionary, organization: organization)
    end
    
    it 'returns success' do
      get :missionaries
      expect(response).to have_http_status(:success)
    end
    
    it 'filters by status' do
      get :missionaries, params: { filter: 'approved' }
      expect(assigns(:filter)).to eq('approved')
    end
  end
  
  describe 'GET #supporters' do
    before do
      Follow.create!(user: supporter, followable: organization)
    end
    
    it 'returns success' do
      get :supporters
      expect(response).to have_http_status(:success)
    end
    
    it 'loads supporters and recent follows' do
      get :supporters
      
      expect(assigns(:supporters)).to include(supporter)
      expect(assigns(:recent_follows)).to be_present
    end
  end
  
  describe 'authentication and authorization' do
    context 'when not signed in' do
      before { sign_out(organization_admin) }
      
      it 'redirects to sign in' do
        get :dashboard
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    
    context 'when not an organization admin' do
      before do
        sign_out(organization_admin)
        sign_in(supporter)
      end
      
      it 'redirects with access denied' do
        get :dashboard
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end
    end
    
    context 'when organization admin without organization' do
      let(:admin_without_org) { FactoryBot.create(:user, :organization_admin, organization: nil) }
      
      before do
        sign_out(organization_admin)
        sign_in(admin_without_org)
      end
      
      it 'redirects with organization not found' do
        get :dashboard
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Organization not found.')
      end
    end
  end
end
