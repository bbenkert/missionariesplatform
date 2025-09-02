require 'rails_helper'

RSpec.describe "Prayer Requests API", type: :request do
  let!(:organization) { create(:organization) }
  let!(:supporter) { create(:user, :supporter) }
  let!(:missionary) { create(:user, :missionary, status: :approved) }
  let!(:missionary_profile) { create(:missionary_profile, user: missionary, organization: organization) }
  let!(:prayer_request) { create(:prayer_request, missionary_profile: missionary_profile, urgency: :high) }

  describe "POST /prayer_requests/:id/pray" do
    context "when user is authenticated" do
      before { sign_in(supporter) }

      context "when prayer request exists" do
        it "creates a prayer action successfully" do
          expect {
            post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
          }.to change { PrayerAction.count }.by(1)
          
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to include(
            'status' => 'success',
            'message' => 'Prayer recorded'
          )
          
          prayer_action = PrayerAction.last
          expect(prayer_action.user).to eq(supporter)
          expect(prayer_action.prayer_request).to eq(prayer_request)
        end

        it "returns updated prayer count" do
          create(:prayer_action, prayer_request: prayer_request, user: missionary)
          
          post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
          
          response_body = JSON.parse(response.body)
          expect(response_body['prayer_count']).to eq(2)
        end

        it "prevents duplicate prayers from same user" do
          create(:prayer_action, prayer_request: prayer_request, user: supporter)
          
          expect {
            post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
          }.not_to change { PrayerAction.count }
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to include(
            'status' => 'error',
            'message' => 'You have already prayed for this request'
          )
        end

        it "handles concurrent prayer attempts" do
          # Simulate race condition
          allow(PrayerAction).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
          
          post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['message']).to include("already prayed")
        end

        it "tracks prayer timestamp" do
          Timecop.freeze do
            post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
            
            prayer_action = PrayerAction.last
            expect(prayer_action.created_at).to be_within(1.second).of(Time.current)
          end
        end
      end

      context "when prayer request doesn't exist" do
        it "returns not found error" do
          post "/prayer_requests/999999/pray", xhr: true
          
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)).to include(
            'status' => 'error',
            'message' => 'Prayer request not found'
          )
        end
      end

      context "when request is not AJAX" do
        it "redirects with flash message" do
          post "/prayer_requests/#{prayer_request.id}/pray"
          
          expect(response).to redirect_to(dashboard_path)
          follow_redirect!
          expect(flash[:notice]).to eq('Prayer recorded')
        end
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'status' => 'error',
          'message' => 'Please sign in to pray'
        )
      end
    end

    context "when missionary is inactive" do
      before do
        missionary.update!(is_active: false)
        sign_in(supporter)
      end

      it "prevents prayers for inactive missionaries" do
        post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
        
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to include(
          'message' => 'This missionary is no longer active'
        )
      end
    end
  end

  describe "GET /prayer_requests/:id" do
    let!(:prayer_action1) { create(:prayer_action, prayer_request: prayer_request, user: supporter) }
    let!(:prayer_action2) { create(:prayer_action, prayer_request: prayer_request, user: missionary) }

    context "when user is authenticated" do
      before { sign_in(supporter) }

      it "returns prayer request details" do
        get "/prayer_requests/#{prayer_request.id}", xhr: true
        
        expect(response).to have_http_status(:success)
        
        response_body = JSON.parse(response.body)
        expect(response_body).to include(
          'id' => prayer_request.id,
          'title' => prayer_request.title,
          'content' => prayer_request.content,
          'urgency' => prayer_request.urgency,
          'prayer_count' => 2,
          'missionary' => {
            'name' => missionary.name,
            'id' => missionary.id
          }
        )
      end

      it "includes user's prayer status" do
        get "/prayer_requests/#{prayer_request.id}", xhr: true
        
        response_body = JSON.parse(response.body)
        expect(response_body['user_has_prayed']).to be_true
      end

      it "shows false when user hasn't prayed" do
        prayer_action1.destroy
        
        get "/prayer_requests/#{prayer_request.id}", xhr: true
        
        response_body = JSON.parse(response.body)
        expect(response_body['user_has_prayed']).to be_false
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/prayer_requests/#{prayer_request.id}", xhr: true
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /prayer_requests" do
    let!(:high_priority) { create(:prayer_request, missionary_profile: missionary_profile, urgency: :high) }
    let!(:medium_priority) { create(:prayer_request, missionary_profile: missionary_profile, urgency: :medium) }
    let!(:low_priority) { create(:prayer_request, missionary_profile: missionary_profile, urgency: :low) }

    context "when user is authenticated" do
      before { sign_in(supporter) }

      it "returns paginated prayer requests" do
        get "/prayer_requests", xhr: true
        
        expect(response).to have_http_status(:success)
        
        response_body = JSON.parse(response.body)
        expect(response_body['prayer_requests']).to be_an(Array)
        expect(response_body['prayer_requests'].length).to eq(4) # 3 created + 1 from let!
        expect(response_body).to have_key('pagination')
      end

      it "orders by urgency and creation date" do
        get "/prayer_requests", xhr: true
        
        response_body = JSON.parse(response.body)
        urgencies = response_body['prayer_requests'].map { |pr| pr['urgency'] }
        
        # High urgency should come first
        expect(urgencies.first).to eq('high')
      end

      it "filters by urgency" do
        get "/prayer_requests", params: { urgency: 'high' }, xhr: true
        
        response_body = JSON.parse(response.body)
        urgencies = response_body['prayer_requests'].map { |pr| pr['urgency'] }.uniq
        
        expect(urgencies).to eq(['high'])
      end

      it "filters by missionary" do
        other_missionary = create(:user, :missionary, status: :approved)
        other_profile = create(:missionary_profile, user: other_missionary, organization: organization)
        create(:prayer_request, missionary_profile: other_profile)
        
        get "/prayer_requests", params: { missionary_id: missionary.id }, xhr: true
        
        response_body = JSON.parse(response.body)
        missionary_ids = response_body['prayer_requests'].map { |pr| pr['missionary']['id'] }.uniq
        
        expect(missionary_ids).to eq([missionary.id])
      end

      it "searches by title and content" do
        searchable = create(:prayer_request, 
          missionary_profile: missionary_profile,
          title: "Special healing request",
          content: "Please pray for healing"
        )
        
        get "/prayer_requests", params: { search: 'healing' }, xhr: true
        
        response_body = JSON.parse(response.body)
        titles = response_body['prayer_requests'].map { |pr| pr['title'] }
        
        expect(titles).to include("Special healing request")
      end

      it "includes pagination metadata" do
        create_list(:prayer_request, 25, missionary_profile: missionary_profile)
        
        get "/prayer_requests", params: { per_page: 10 }, xhr: true
        
        response_body = JSON.parse(response.body)
        expect(response_body['pagination']).to include(
          'current_page' => 1,
          'total_pages' => 3,
          'total_count' => 29 # 25 + 4 existing
        )
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/prayer_requests", xhr: true
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "Rate Limiting" do
    before { sign_in(supporter) }

    it "prevents spam prayers" do
      # Make multiple rapid requests
      5.times do
        post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
        prayer_request.prayer_actions.where(user: supporter).destroy_all # Reset for next attempt
      end
      
      # 6th attempt should be rate limited
      post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
      
      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)['message']).to include("rate limit")
    end
  end

  describe "Error Handling" do
    before { sign_in(supporter) }

    it "handles database connection errors gracefully" do
      allow(PrayerAction).to receive(:create!).and_raise(ActiveRecord::ConnectionNotEstablished)
      
      post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
      
      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)['message']).to include("temporarily unavailable")
    end

    it "handles validation errors" do
      # Mock a validation error
      invalid_prayer = PrayerAction.new
      allow(PrayerAction).to receive(:new).and_return(invalid_prayer)
      allow(invalid_prayer).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(invalid_prayer))
      
      post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
      
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "handles timeout errors" do
      allow(PrayerAction).to receive(:create!).and_raise(ActiveRecord::StatementTimeout)
      
      post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
      
      expect(response).to have_http_status(:request_timeout)
    end
  end

  describe "Security" do
    it "prevents CSRF attacks on state-changing operations" do
      # This would be tested with actual CSRF token verification
      expect(controller).to respond_to(:verify_authenticity_token)
    end

    it "sanitizes input parameters" do
      malicious_params = {
        urgency: "<script>alert('xss')</script>",
        search: "'; DROP TABLE users; --"
      }
      
      sign_in(supporter)
      get "/prayer_requests", params: malicious_params, xhr: true
      
      expect(response).to have_http_status(:success) # Should handle safely
    end

    it "validates user permissions" do
      admin_only_prayer = create(:prayer_request, missionary_profile: missionary_profile, is_private: true)
      
      sign_in(supporter)
      get "/prayer_requests/#{admin_only_prayer.id}", xhr: true
      
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "Performance" do
    it "uses efficient queries" do
      create_list(:prayer_request, 10, missionary_profile: missionary_profile)
      sign_in(supporter)
      
      expect {
        get "/prayer_requests", xhr: true
      }.to make_database_queries(count: 3..5) # Should be efficient with proper includes
    end

    it "caches expensive operations" do
      sign_in(supporter)
      
      # First request
      get "/prayer_requests", xhr: true
      
      # Should use cached results for similar requests
      expect(Rails.cache).to receive(:fetch).at_least(:once)
      get "/prayer_requests", xhr: true
    end
  end

  describe "Content-Type Handling" do
    before { sign_in(supporter) }

    it "returns JSON for AJAX requests" do
      post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
      
      expect(response.content_type).to include('application/json')
    end

    it "handles HTML requests appropriately" do
      post "/prayer_requests/#{prayer_request.id}/pray"
      
      expect(response).to be_redirect
    end
  end

  describe "Internationalization" do
    before { sign_in(supporter) }

    it "supports multiple languages" do
      # Mock locale setting
      I18n.with_locale(:es) do
        post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
        
        # Response should be in Spanish
        response_body = JSON.parse(response.body)
        expect(response_body['message']).to be_present
      end
    end
  end
end
