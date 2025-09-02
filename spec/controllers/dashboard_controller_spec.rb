require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let!(:supporter) { create(:user, :supporter, name: "John Supporter") }
  let!(:missionary) { create(:user, :missionary, status: :approved, name: "Jane Missionary") }
  let!(:admin) { create(:user, :admin, name: "Admin User") }
  let!(:organization) { create(:organization, name: "Global Missions") }
  let!(:missionary_profile) { create(:missionary_profile, user: missionary, organization: organization) }

  describe "GET #index" do
    context "when user is not signed in" do
      it "redirects to sign in page" do
        get :index
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when supporter is signed in" do
      before { session[:user_id] = supporter.id }

      it "renders supporter dashboard" do
        get :index
        
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:supporter)
        expect(assigns(:current_user)).to eq(supporter)
      end

      it "loads followed missionaries" do
        follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
        
        get :index
        
        expect(assigns(:followed_missionary_profiles)).to include(missionary_profile)
      end

      it "loads recent updates from followed missionaries" do
        follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
        update = create(:missionary_update, missionary_profile: missionary_profile, created_at: 1.day.ago)
        
        get :index
        
        expect(assigns(:recent_updates)).to include(update)
      end

      it "orders updates by most recent first" do
        follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
        older_update = create(:missionary_update, missionary_profile: missionary_profile, created_at: 2.days.ago)
        newer_update = create(:missionary_update, missionary_profile: missionary_profile, created_at: 1.day.ago)
        
        get :index
        
        expect(assigns(:recent_updates).first).to eq(newer_update)
        expect(assigns(:recent_updates).second).to eq(older_update)
      end

      it "loads prayer requests from followed missionaries" do
        follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
        prayer_request = create(:prayer_request, missionary_profile: missionary_profile)
        
        get :index
        
        expect(assigns(:prayer_requests)).to include(prayer_request)
      end

      it "includes prayer counts for each request" do
        follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
        prayer_request = create(:prayer_request, missionary_profile: missionary_profile)
        create(:prayer_action, prayer_request: prayer_request, user: supporter)
        create(:prayer_action, prayer_request: prayer_request, user: missionary)
        
        get :index
        
        loaded_request = assigns(:prayer_requests).find { |pr| pr.id == prayer_request.id }
        expect(loaded_request.prayer_actions.count).to eq(2)
      end

      it "limits recent updates to prevent overwhelming UI" do
        follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
        create_list(:missionary_update, 25, missionary_profile: missionary_profile)
        
        get :index
        
        expect(assigns(:recent_updates).count).to be <= 20
      end

      it "limits prayer requests to most urgent" do
        follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
        create_list(:prayer_request, 15, missionary_profile: missionary_profile, urgency: :low)
        create_list(:prayer_request, 5, missionary_profile: missionary_profile, urgency: :high)
        
        get :index
        
        expect(assigns(:prayer_requests).count).to be <= 10
        # High urgency requests should be prioritized
        high_urgency_count = assigns(:prayer_requests).select { |pr| pr.urgency == 'high' }.count
        expect(high_urgency_count).to eq(5)
      end

      it "excludes updates and prayers from unfollowed missionaries" do
        other_missionary = create(:user, :missionary, status: :approved)
        other_profile = create(:missionary_profile, user: other_missionary, organization: organization)
        other_update = create(:missionary_update, missionary_profile: other_profile)
        other_prayer = create(:prayer_request, missionary_profile: other_profile)
        
        get :index
        
        expect(assigns(:recent_updates)).not_to include(other_update)
        expect(assigns(:prayer_requests)).not_to include(other_prayer)
      end
    end

    context "when missionary is signed in" do
      before { session[:user_id] = missionary.id }

      it "renders missionary dashboard" do
        get :index
        
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:missionary)
        expect(assigns(:current_user)).to eq(missionary)
      end

      it "loads missionary's own updates" do
        update = create(:missionary_update, missionary_profile: missionary_profile)
        
        get :index
        
        expect(assigns(:my_updates)).to include(update)
      end

      it "loads missionary's prayer requests" do
        prayer_request = create(:prayer_request, missionary_profile: missionary_profile)
        
        get :index
        
        expect(assigns(:my_prayer_requests)).to include(prayer_request)
      end

      it "loads follower statistics" do
        create(:follow, follower: supporter, missionary_profile: missionary_profile)
        other_supporter = create(:user, :supporter)
        create(:follow, follower: other_supporter, missionary_profile: missionary_profile)
        
        get :index
        
        expect(assigns(:followers_count)).to eq(2)
      end
    end

    context "when admin is signed in" do
      before { session[:user_id] = admin.id }

      it "redirects to admin dashboard" do
        get :index
        
        expect(response).to redirect_to(admin_dashboard_path)
      end
    end

    context "when pending missionary is signed in" do
      let!(:pending_missionary) { create(:user, :missionary, status: :pending) }

      before { session[:user_id] = pending_missionary.id }

      it "shows pending approval message" do
        get :index
        
        expect(response).to have_http_status(:success)
        expect(assigns(:current_user)).to eq(pending_missionary)
        expect(flash[:notice]).to include("pending approval")
      end
    end
  end

  describe "GET #supporter" do
    before { session[:user_id] = supporter.id }

    it "returns success" do
      get :supporter
      
      expect(response).to have_http_status(:success)
    end

    it "loads supporter-specific data efficiently" do
      # Create test data
      follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
      update = create(:missionary_update, missionary_profile: missionary_profile)
      prayer_request = create(:prayer_request, missionary_profile: missionary_profile)
      
      # Expect optimized queries with includes
      expect(controller).to receive(:load_supporter_data).and_call_original
      
      get :supporter
      
      expect(assigns(:followed_missionary_profiles)).to be_loaded
      expect(assigns(:recent_updates)).to be_loaded
      expect(assigns(:prayer_requests)).to be_loaded
    end

    it "handles empty state gracefully" do
      get :supporter
      
      expect(assigns(:followed_missionary_profiles)).to be_empty
      expect(assigns(:recent_updates)).to be_empty
      expect(assigns(:prayer_requests)).to be_empty
      expect(response).to have_http_status(:success)
    end
  end

  describe "Private methods" do
    before { session[:user_id] = supporter.id }

    describe "#load_supporter_data" do
      it "uses efficient queries with proper includes" do
        follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
        
        # Test that associations are included to prevent N+1 queries
        expect {
          controller.send(:load_supporter_data)
        }.to make_database_queries(count: 3..5) # Adjust based on actual query count
      end
    end

    describe "#redirect_based_on_role" do
      it "redirects admin users" do
        allow(controller).to receive(:current_user).and_return(admin)
        
        controller.send(:redirect_based_on_role)
        
        expect(response).to redirect_to(admin_dashboard_path)
      end

      it "shows pending message for pending missionaries" do
        pending_missionary = create(:user, :missionary, status: :pending)
        allow(controller).to receive(:current_user).and_return(pending_missionary)
        
        controller.send(:redirect_based_on_role)
        
        expect(flash[:notice]).to include("pending approval")
      end

      it "does not redirect supporters" do
        allow(controller).to receive(:current_user).and_return(supporter)
        
        controller.send(:redirect_based_on_role)
        
        expect(response).not_to be_redirect
      end
    end
  end

  describe "Performance considerations" do
    before { session[:user_id] = supporter.id }

    it "limits database queries through proper eager loading" do
      # Setup data
      follow = create(:follow, follower: supporter, missionary_profile: missionary_profile)
      create_list(:missionary_update, 5, missionary_profile: missionary_profile)
      create_list(:prayer_request, 5, missionary_profile: missionary_profile)
      
      expect {
        get :index
      }.to make_database_queries(count: 5..10) # Should be reasonably low due to includes
    end

    it "handles large datasets efficiently" do
      # Create many followed missionaries
      missionaries = create_list(:user, 10, :missionary, status: :approved)
      missionary_profiles = missionaries.map do |m|
        profile = create(:missionary_profile, user: m, organization: organization)
        create(:follow, follower: supporter, missionary_profile: profile)
        profile
      end
      
      # Create many updates and prayer requests
      missionary_profiles.each do |profile|
        create_list(:missionary_update, 5, missionary_profile: profile)
        create_list(:prayer_request, 3, missionary_profile: profile)
      end
      
      expect {
        get :index
      }.to complete_within(2.seconds)
    end

    context 'when user is authenticated' do
      context 'admin user' do
        let(:admin) { create(:user, :admin) }

        before do
          sign_in(admin)
        end

        it 'redirects to admin root path' do
          get :index
          expect(response).to redirect_to(admin_root_path)
        end
      end

      context 'missionary user' do
        let(:missionary) { create(:user, :missionary) }

        before do
          sign_in(missionary)
        end

        it 'redirects to missionary dashboard' do
          get :index
          expect(response).to redirect_to(missionaries_path)
        end
      end

      context 'supporter user' do
        let(:supporter) { create(:user, :supporter) }

        before do
          sign_in(supporter)
        end

        it 'redirects to supporter dashboard' do
          get :index
          expect(response).to redirect_to(missionaries_path)
        end
      end

      context 'user with unknown role' do
        let(:user) { create(:user) }

        before do
          user.update(role: 'unknown')
          sign_in(user)
        end

        it 'redirects to root path with alert' do
          get :index
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('Please complete your profile setup')
        end
      end
    end
  end

  describe 'private methods' do
    describe '#missionary_dashboard_path' do
      it 'returns missionaries path' do
        controller = DashboardController.new
        expect(controller.send(:missionary_dashboard_path)).to eq(missionaries_path)
      end
    end

    describe '#supporter_dashboard_path' do
      it 'returns missionaries path' do
        controller = DashboardController.new
        expect(controller.send(:supporter_dashboard_path)).to eq(missionaries_path)
      end
    end
  end
end
