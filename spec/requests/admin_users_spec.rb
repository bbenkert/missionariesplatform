require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:supporter) { create(:user, :supporter) }
  let(:missionary) { create(:user, :missionary) }
  let(:org_admin) { create(:user, :organization_admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #index' do
    let!(:users) { [supporter, missionary, org_admin] }

    it 'returns successful response' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns all users' do
      get :index
      expect(assigns(:users)).to match_array([admin, supporter, missionary, org_admin])
    end

    context 'with role filter' do
      it 'filters by supporter role' do
        get :index, params: { role: 'supporter' }
        expect(assigns(:users)).to contain_exactly(supporter)
      end

      it 'filters by missionary role' do
        get :index, params: { role: 'missionary' }
        expect(assigns(:users)).to contain_exactly(missionary)
      end
    end

    context 'with status filter' do
      let!(:suspended_user) { create(:user, :suspended) }

      it 'filters by status' do
        get :index, params: { status: 'suspended' }
        expect(assigns(:users)).to contain_exactly(suspended_user)
      end
    end

    context 'with search' do
      let!(:john) { create(:user, name: 'John Doe', email: 'john@example.com') }

      it 'searches by name' do
        get :index, params: { search: 'John' }
        expect(assigns(:users)).to include(john)
      end

      it 'searches by email' do
        get :index, params: { search: 'john@example.com' }
        expect(assigns(:users)).to include(john)
      end
    end

    it 'calculates user statistics' do
      get :index
      stats = assigns(:stats)
      expect(stats[:total_users]).to eq(4)
      expect(stats[:supporters]).to eq(1)
      expect(stats[:missionaries]).to eq(1)
      expect(stats[:pending_users]).to eq(1) # missionary is pending by default
    end
  end

  describe 'GET #show' do
    it 'returns successful response' do
      get :show, params: { id: supporter.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns the user' do
      get :show, params: { id: supporter.id }
      expect(assigns(:user)).to eq(supporter)
    end

    it 'assigns email logs' do
      email_log = create(:email_log, user: supporter)
      get :show, params: { id: supporter.id }
      expect(assigns(:email_logs)).to include(email_log)
    end

    it 'assigns notifications' do
      notification = create(:notification, user: supporter)
      get :show, params: { id: supporter.id }
      expect(assigns(:notifications)).to include(notification)
    end

    it 'calculates user activity' do
      get :show, params: { id: supporter.id }
      activity = assigns(:recent_activity)
      expect(activity).to be_an(Array)
    end
  end

  describe 'GET #edit' do
    it 'returns successful response' do
      get :edit, params: { id: supporter.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns the user' do
      get :edit, params: { id: supporter.id }
      expect(assigns(:user)).to eq(supporter)
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) do
      {
        name: 'Updated Name',
        email: 'updated@example.com',
        role: 'supporter',
        status: 'approved'
      }
    end

    it 'updates the user' do
      patch :update, params: { id: supporter.id, user: new_attributes }
      supporter.reload
      expect(supporter.name).to eq('Updated Name')
      expect(supporter.email).to eq('updated@example.com')
    end

    it 'redirects to user show page' do
      patch :update, params: { id: supporter.id, user: new_attributes }
      expect(response).to redirect_to(admin_user_path(supporter))
    end

    it 'sets success flash message' do
      patch :update, params: { id: supporter.id, user: new_attributes }
      expect(flash[:notice]).to include('User updated successfully')
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { { name: '', email: '' } }

      it 'renders edit template' do
        patch :update, params: { id: supporter.id, user: invalid_attributes }
        expect(response).to render_template(:edit)
      end

      it 'sets error flash message' do
        patch :update, params: { id: supporter.id, user: invalid_attributes }
        expect(flash.now[:alert]).to be_present
      end
    end
  end

  describe 'PATCH #bulk_actions' do
    let!(:users_to_act_on) { [supporter, missionary] }
    let(:user_ids) { users_to_act_on.map(&:id) }

    context 'approve_missionaries action' do
      it 'approves selected missionary users' do
        patch :bulk_actions, params: { 
          action_type: 'approve_missionaries', 
          user_ids: user_ids 
        }
        
        missionary.reload
        expect(missionary.status).to eq('approved')
      end

      it 'creates missionary profiles for approved missionaries' do
        expect {
          patch :bulk_actions, params: { 
            action_type: 'approve_missionaries', 
            user_ids: [missionary.id] 
          }
        }.to change { missionary.reload.missionary_profile.present? }.to(true)
      end
    end

    context 'suspend action' do
      it 'suspends selected users' do
        patch :bulk_actions, params: { 
          action_type: 'suspend', 
          user_ids: user_ids 
        }
        
        users_to_act_on.each(&:reload)
        users_to_act_on.each do |user|
          expect(user.status).to eq('suspended')
        end
      end
    end

    context 'activate action' do
      let!(:suspended_users) do
        [
          create(:user, :suspended),
          create(:user, :suspended)
        ]
      end

      it 'activates suspended users' do
        patch :bulk_actions, params: { 
          action_type: 'activate', 
          user_ids: suspended_users.map(&:id) 
        }
        
        suspended_users.each(&:reload)
        suspended_users.each do |user|
          expect(user.status).to eq('approved')
        end
      end
    end

    context 'delete action' do
      it 'deletes selected users' do
        expect {
          patch :bulk_actions, params: { 
            action_type: 'delete', 
            user_ids: user_ids 
          }
        }.to change(User, :count).by(-2)
      end
    end

    it 'redirects back to index' do
      patch :bulk_actions, params: { 
        action_type: 'suspend', 
        user_ids: user_ids 
      }
      expect(response).to redirect_to(admin_users_path)
    end

    it 'sets success flash message' do
      patch :bulk_actions, params: { 
        action_type: 'suspend', 
        user_ids: user_ids 
      }
      expect(flash[:notice]).to include('Bulk action completed successfully')
    end
  end

  describe 'PATCH #approve_missionary' do
    it 'approves the missionary' do
      patch :approve_missionary, params: { id: missionary.id }
      missionary.reload
      expect(missionary.status).to eq('approved')
    end

    it 'creates missionary profile' do
      expect {
        patch :approve_missionary, params: { id: missionary.id }
      }.to change { missionary.reload.missionary_profile.present? }.to(true)
    end

    it 'redirects to user show page' do
      patch :approve_missionary, params: { id: missionary.id }
      expect(response).to redirect_to(admin_user_path(missionary))
    end
  end

  describe 'PATCH #suspend' do
    it 'suspends the user' do
      patch :suspend, params: { id: supporter.id }
      supporter.reload
      expect(supporter.status).to eq('suspended')
    end

    it 'redirects to user show page' do
      patch :suspend, params: { id: supporter.id }
      expect(response).to redirect_to(admin_user_path(supporter))
    end
  end

  describe 'PATCH #activate' do
    let(:suspended_user) { create(:user, :suspended) }

    it 'activates the user' do
      patch :activate, params: { id: suspended_user.id }
      suspended_user.reload
      expect(suspended_user.status).to eq('approved')
    end

    it 'redirects to user show page' do
      patch :activate, params: { id: suspended_user.id }
      expect(response).to redirect_to(admin_user_path(suspended_user))
    end
  end

  context 'authorization' do
    context 'when user is not admin' do
      before { sign_out(admin) && sign_in(supporter) }

      it 'redirects to unauthorized page' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not signed in' do
      before { sign_out(admin) }

      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
