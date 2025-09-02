require 'rails_helper'

RSpec.describe PrayerRequestsController, type: :controller do
  include Devise::Test::ControllerHelpers
  
  let(:user) { create(:user) }
  let(:missionary_profile) { create(:missionary_profile, user: user, safety_mode: :public_mode) }
  let(:prayer_request) { create(:prayer_request, missionary_profile: missionary_profile) }

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end

    it "only shows prayer requests from public missionary profiles" do
      public_request = create(:prayer_request, missionary_profile: missionary_profile)
      private_profile = create(:missionary_profile, safety_mode: :private_mode)
      private_request = create(:prayer_request, missionary_profile: private_profile)
      
      get :index
      expect(assigns(:prayer_requests)).to include(public_request)
      expect(assigns(:prayer_requests)).not_to include(private_request)
    end

    it "filters by search term" do
      matching_request = create(:prayer_request, title: "Healing prayer", missionary_profile: missionary_profile)
      non_matching_request = create(:prayer_request, title: "Travel safety", missionary_profile: missionary_profile)
      
      get :index, params: { search: "healing" }
      expect(assigns(:prayer_requests)).to include(matching_request)
      expect(assigns(:prayer_requests)).not_to include(non_matching_request)
    end

    it "filters by tag" do
      tagged_request = create(:prayer_request, tags: ['healing'], missionary_profile: missionary_profile)
      untagged_request = create(:prayer_request, tags: ['travel'], missionary_profile: missionary_profile)
      
      get :index, params: { tag: "healing" }
      expect(assigns(:prayer_requests)).to include(tagged_request)
      expect(assigns(:prayer_requests)).not_to include(untagged_request)
    end

    it "filters by urgency" do
      urgent_request = create(:prayer_request, urgency: :high, missionary_profile: missionary_profile)
      normal_request = create(:prayer_request, urgency: :low, missionary_profile: missionary_profile)
      
      get :index, params: { urgency: "high" }
      expect(assigns(:prayer_requests)).to include(urgent_request)
      expect(assigns(:prayer_requests)).not_to include(normal_request)
    end
  end

  describe "GET #show" do
    context "when prayer request is from public missionary profile" do
      it "returns a success response" do
        get :show, params: { id: prayer_request.id }
        expect(response).to be_successful
      end
    end

    context "when prayer request is from private missionary profile" do
      let(:private_profile) { create(:missionary_profile, safety_mode: :private_mode) }
      let(:private_request) { create(:prayer_request, missionary_profile: private_profile) }

      it "redirects unauthorized users" do
        get :show, params: { id: private_request.id }
        expect(response).to redirect_to(prayer_requests_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when prayer request is from limited missionary profile and user is following" do
      let(:follower) { create(:user) }
      let(:limited_profile) { create(:missionary_profile, safety_mode: :limited_mode) }
      let(:limited_request) { create(:prayer_request, missionary_profile: limited_profile) }

      before do
        create(:follow, user: follower, followable: limited_profile)
        sign_in follower
      end

      it "allows followers to view" do
        get :show, params: { id: limited_request.id }
        expect(response).to be_successful
      end
    end
  end

  describe "POST #pray" do
    before { sign_in user }

    it "creates a prayer action" do
      expect {
        post :pray, params: { id: prayer_request.id }
      }.to change(PrayerAction, :count).by(1)
      
      expect(response).to redirect_to(prayer_request)
      expect(flash[:notice]).to be_present
    end

    it "doesn't create duplicate prayer actions" do
      create(:prayer_action, user: user, prayer_request: prayer_request)
      
      expect {
        post :pray, params: { id: prayer_request.id }
      }.not_to change(PrayerAction, :count)
      
      expect(response).to redirect_to(prayer_request)
    end
  end

  describe "authenticated actions" do
    context "when user is not signed in" do
      it "redirects to sign in for new" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to sign in for create" do
        post :create, params: { prayer_request: { title: "Test", body: "Test body" } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to sign in for pray" do
        post :pray, params: { id: prayer_request.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "missionary profile requirement" do
    before { sign_in user }

    context "when user doesn't have a missionary profile" do
      it "redirects to create missionary profile for new" do
        get :new
        expect(response).to redirect_to(edit_profile_path)
        expect(flash[:alert]).to be_present
      end

      it "redirects to create missionary profile for create" do
        post :create, params: { prayer_request: { title: "Test", body: "Test body" } }
        expect(response).to redirect_to(edit_profile_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "prayer request ownership" do
    let(:other_user) { create(:user) }
    let(:other_profile) { create(:missionary_profile, user: other_user) }
    let(:other_request) { create(:prayer_request, missionary_profile: other_profile) }

    before { sign_in user }

    it "prevents editing other users' prayer requests" do
      get :edit, params: { id: other_request.id }
      expect(response).to redirect_to(prayer_requests_path)
      expect(flash[:alert]).to be_present
    end

    it "prevents updating other users' prayer requests" do
      patch :update, params: { id: other_request.id, prayer_request: { title: "New title" } }
      expect(response).to redirect_to(prayer_requests_path)
      expect(flash[:alert]).to be_present
    end

    it "prevents deleting other users' prayer requests" do
      delete :destroy, params: { id: other_request.id }
      expect(response).to redirect_to(prayer_requests_path)
      expect(flash[:alert]).to be_present
    end
  end
end
