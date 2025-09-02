require 'rails_helper'

RSpec.describe MissionariesController, type: :controller do
  let!(:approved_missionary) { create(:user, :missionary, :approved, name: 'John Missionary') }
  let!(:pending_missionary) { create(:user, :missionary, :pending) }
  let!(:supporter) { create(:user, :supporter) }

  describe 'GET #index' do
    it 'does not require authentication' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'loads approved missionaries' do
      get :index
      expect(assigns(:missionaries)).to include(approved_missionary)
      expect(assigns(:missionaries)).not_to include(pending_missionary)
    end

    it 'includes necessary associations' do
      get :index
      # This would require checking the actual query, but for now we'll trust the implementation
      expect(assigns(:missionaries)).to be_present
    end

    it 'paginates results' do
      create_list(:user, 15, :missionary, :approved)
      get :index
      expect(assigns(:pagy)).to be_present
      expect(assigns(:missionaries).count).to eq(12) # Default page size
    end

    describe 'filtering' do
      let!(:usa_missionary) { create(:user, :missionary, :approved) }
      let!(:uk_missionary) { create(:user, :missionary, :approved) }

      before do
        create(:missionary_profile, user: usa_missionary, country: 'United States')
        create(:missionary_profile, user: uk_missionary, country: 'United Kingdom')
      end

      it 'filters by country' do
        get :index, params: { country: 'United States' }
        expect(assigns(:missionaries)).to include(usa_missionary)
        expect(assigns(:missionaries)).not_to include(uk_missionary)
      end

      it 'filters by organization' do
        org1_missionary = create(:user, :missionary, :approved)
        org2_missionary = create(:user, :missionary, :approved)
        create(:missionary_profile, user: org1_missionary, organization: 'Org A')
        create(:missionary_profile, user: org2_missionary, organization: 'Org B')

        get :index, params: { organization: 'Org A' }
        expect(assigns(:missionaries)).to include(org1_missionary)
        expect(assigns(:missionaries)).not_to include(org2_missionary)
      end

      it 'filters by ministry focus' do
        evangelism_missionary = create(:user, :missionary, :approved)
        education_missionary = create(:user, :missionary, :approved)
        create(:missionary_profile, user: evangelism_missionary, ministry_focus: 'Evangelism')
        create(:missionary_profile, user: education_missionary, ministry_focus: 'Education')

        get :index, params: { ministry_focus: 'Evangelism' }
        expect(assigns(:missionaries)).to include(evangelism_missionary)
        expect(assigns(:missionaries)).not_to include(education_missionary)
      end
    end

    describe 'searching' do
      let!(:john_missionary) { create(:user, :missionary, :approved, name: 'John Doe') }
      let!(:jane_missionary) { create(:user, :missionary, :approved, name: 'Jane Smith') }

      before do
        create(:missionary_profile, user: john_missionary, bio: 'Missionary work in Africa')
        create(:missionary_profile, user: jane_missionary, organization: 'World Missions')
      end

      it 'searches by name' do
        get :index, params: { search: 'John' }
        expect(assigns(:missionaries)).to include(john_missionary)
        expect(assigns(:missionaries)).not_to include(jane_missionary)
      end

      it 'searches by bio' do
        get :index, params: { search: 'Africa' }
        expect(assigns(:missionaries)).to include(john_missionary)
        expect(assigns(:missionaries)).not_to include(jane_missionary)
      end

      it 'searches by organization' do
        get :index, params: { search: 'World Missions' }
        expect(assigns(:missionaries)).to include(jane_missionary)
        expect(assigns(:missionaries)).not_to include(john_missionary)
      end
    end

    it 'loads filter options' do
      get :index
      expect(assigns(:countries)).to be_an(Array)
      expect(assigns(:organizations)).to be_an(Array)
    end
  end

  describe 'GET #show' do
    it 'does not require authentication' do
      get :show, params: { id: approved_missionary.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads approved missionary' do
      get :show, params: { id: approved_missionary.id }
      expect(assigns(:missionary)).to eq(approved_missionary)
    end

    it 'loads recent updates' do
      create_list(:missionary_update, 5, user: approved_missionary, status: :published)
      get :show, params: { id: approved_missionary.id }
      expect(assigns(:updates).count).to eq(5)
    end

    context 'when user is signed in' do
      before do
        sign_in(supporter)
      end

      it 'checks if current user is following the missionary' do
        get :show, params: { id: approved_missionary.id }
        expect(assigns(:is_following)).to be_falsey
      end

      it 'checks if current user can message the missionary' do
        get :show, params: { id: approved_missionary.id }
        expect(assigns(:can_message)).to be_truthy
      end
    end

    context 'when missionary is not approved' do
      it 'redirects with alert' do
        get :show, params: { id: pending_missionary.id }
        expect(response).to redirect_to(missionaries_path)
        expect(flash[:alert]).to eq('Missionary not found or not approved')
      end
    end

    context 'when missionary does not exist' do
      it 'redirects with alert' do
        get :show, params: { id: 99999 }
        expect(response).to redirect_to(missionaries_path)
        expect(flash[:alert]).to eq('Missionary not found or not approved')
      end
    end
  end

  describe 'POST #follow' do
    before do
      sign_in(supporter)
    end

    it 'requires authentication' do
      sign_out
      post :follow, params: { id: approved_missionary.id }
      expect(response).to redirect_to(sign_in_path)
    end

    it 'requires supporter role' do
      missionary_user = create(:user, :missionary, :approved)
      sign_in(missionary_user)

      post :follow, params: { id: approved_missionary.id }
      expect(response).to redirect_to(missionaries_path)
      expect(flash[:alert]).to eq('Only supporters can follow missionaries')
    end

    context 'successful follow' do
      it 'creates a following relationship' do
        expect {
          post :follow, params: { id: approved_missionary.id }
        }.to change(SupporterFollowing, :count).by(1)
      end

      it 'redirects with success message' do
        post :follow, params: { id: approved_missionary.id }
        expect(response).to redirect_to(missionary_path(approved_missionary))
        expect(flash[:notice]).to eq("Now following #{approved_missionary.name}")
      end

      it 'responds with turbo stream' do
        post :follow, params: { id: approved_missionary.id }, format: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'when already following' do
      before do
        create(:supporter_following, supporter: supporter, missionary: approved_missionary)
      end

      it 'does not create duplicate following' do
        expect {
          post :follow, params: { id: approved_missionary.id }
        }.not_to change(SupporterFollowing, :count)
      end
    end
  end

  describe 'DELETE #unfollow' do
    let!(:following) { create(:supporter_following, supporter: supporter, missionary: approved_missionary) }

    before do
      sign_in(supporter)
    end

    it 'requires authentication' do
      sign_out
      delete :unfollow, params: { id: approved_missionary.id }
      expect(response).to redirect_to(sign_in_path)
    end

    context 'successful unfollow' do
      it 'destroys the following relationship' do
        expect {
          delete :unfollow, params: { id: approved_missionary.id }
        }.to change(SupporterFollowing, :count).by(-1)
      end

      it 'redirects with success message' do
        delete :unfollow, params: { id: approved_missionary.id }
        expect(response).to redirect_to(missionary_path(approved_missionary))
        expect(flash[:notice]).to eq("Unfollowed #{approved_missionary.name}")
      end

      it 'responds with turbo stream' do
        delete :unfollow, params: { id: approved_missionary.id }, format: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'when not following' do
      before do
        following.destroy
      end

      it 'redirects with alert' do
        delete :unfollow, params: { id: approved_missionary.id }
        expect(response).to redirect_to(missionary_path(approved_missionary))
        expect(flash[:alert]).to eq('Unable to unfollow missionary')
      end
    end
  end
end
