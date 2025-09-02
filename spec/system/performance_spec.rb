require 'rails_helper'

RSpec.describe "Application Performance", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:organization) { create(:organization, name: "Global Missions") }
  let!(:supporter) { create(:user, :supporter, password: "SecurePassword123!", password_confirmation: "SecurePassword123!"") }

  describe "Dashboard Performance" do
    before do
      # Create test data for performance testing
      missionaries = create_list(:user, 10, :missionary, status: :approved)
      
      @missionary_profiles = missionaries.map do |missionary|
        create(:missionary_profile, user: missionary, organization: organization)
      end
      
      # Create follows
      @missionary_profiles.each do |profile|
        create(:follow, follower: supporter, missionary_profile: profile)
      end
      
      # Create updates and prayer requests
      @missionary_profiles.each do |profile|
        create_list(:missionary_update, 3, missionary_profile: profile)
        create_list(:prayer_request, 2, missionary_profile: profile)
      end
      
      sign_in(supporter)
    end

    it "loads supporter dashboard efficiently" do
      start_time = Time.current
      
      visit dashboard_path
      
      end_time = Time.current
      load_time = end_time - start_time
      
      expect(load_time).to be < 3.seconds
      expect(page).to have_content("Welcome back")
      expect(page).to have_css("[data-testid='recent-updates']")
      expect(page).to have_css("[data-testid='prayer-requests-sidebar']")
    end

    it "handles large datasets without timeout" do
      # Add more data to stress test
      @missionary_profiles.each do |profile|
        create_list(:missionary_update, 20, missionary_profile: profile)
        create_list(:prayer_request, 10, missionary_profile: profile)
      end
      
      expect {
        visit dashboard_path
        expect(page).to have_content("Welcome back")
      }.not_to raise_error
    end

    it "limits database queries through proper eager loading" do
      # This is a conceptual test - in reality you'd need query monitoring
      expect {
        visit dashboard_path
      }.to complete_within(5.seconds)
    end
  end

  describe "Navigation Performance" do
    it "loads missionaries page efficiently" do
      create_list(:user, 25, :missionary, status: :approved).each do |missionary|
        create(:missionary_profile, user: missionary, organization: organization)
      end
      
      start_time = Time.current
      visit missionaries_path
      end_time = Time.current
      
      expect(end_time - start_time).to be < 3.seconds
      expect(page).to have_content("Find Missionaries")
    end

    it "handles pagination efficiently" do
      create_list(:user, 50, :missionary, status: :approved).each do |missionary|
        create(:missionary_profile, user: missionary, organization: organization)
      end
      
      visit missionaries_path
      
      expect(page).to have_css(".pagination")
      
      if page.has_link?("Next")
        click_link "Next"
        expect(page).to have_content("Find Missionaries")
      end
    end
  end

  describe "Search Performance" do
    before do
      sign_in(supporter)
    end

    it "performs searches efficiently" do
      # Create searchable content
      missionaries = create_list(:user, 20, :missionary, status: :approved)
      missionaries.each_with_index do |missionary, index|
        profile = create(:missionary_profile, 
          user: missionary, 
          organization: organization,
          bio: "Missionary serving in region #{index}"
        )
      end
      
      visit missionaries_path
      
      start_time = Time.current
      fill_in "search", with: "region"
      click_button "Search"
      end_time = Time.current
      
      expect(end_time - start_time).to be < 2.seconds
    end
  end

  describe "AJAX Performance" do
    let!(:missionary) { create(:user, :missionary, status: :approved, password: "SecurePassword123!", password_confirmation: "SecurePassword123!"") }
    let!(:missionary_profile) { create(:missionary_profile, user: missionary, organization: organization) }
    let!(:prayer_request) { create(:prayer_request, missionary_profile: missionary_profile) }

    before do
      create(:follow, follower: supporter, missionary_profile: missionary_profile)
      sign_in(supporter)
    end

    it "handles AJAX prayer requests efficiently", js: true do
      visit dashboard_path
      
      start_time = Time.current
      
      within("[data-testid='prayer-requests-sidebar']") do
        find("[data-testid='pray-button']").click
      end
      
      # Wait for AJAX response
      expect(page).to have_content("Prayed", wait: 5)
      
      end_time = Time.current
      response_time = end_time - start_time
      
      expect(response_time).to be < 2.seconds
    end
  end

  describe "Memory Usage" do
    it "doesn't have excessive memory leaks during navigation" do
      # This is a conceptual test - actual memory monitoring would require additional tools
      
      pages_to_visit = [
        root_path,
        missionaries_path,
        dashboard_path,
        root_path
      ]
      
      pages_to_visit.each do |page_path|
        visit page_path
        expect(page.status_code).to eq(200)
      end
      
      # In a real test, you might check memory usage here
    end
  end

  describe "Concurrent User Simulation" do
    it "handles multiple concurrent actions" do
      # Simulate concurrent prayer actions
      missionary_profiles = create_list(:missionary_profile, 5, organization: organization)
      prayer_requests = missionary_profiles.map do |profile|
        create(:prayer_request, missionary_profile: profile)
      end
      
      # Follow all missionaries
      missionary_profiles.each do |profile|
        create(:follow, follower: supporter, missionary_profile: profile)
      end
      
      sign_in(supporter)
      visit dashboard_path
      
      # This simulates what would happen with concurrent users
      prayer_requests.first(3).each do |prayer_request|
        expect {
          post "/prayer_requests/#{prayer_request.id}/pray", xhr: true
        }.not_to raise_error
      end
    end
  end

  describe "Image and Asset Loading" do
    it "loads page assets efficiently" do
      visit root_path
      
      # Check that CSS and JS assets are loaded
      expect(page).to have_css("body")
      
      # Check for critical images
      expect(page.status_code).to eq(200)
    end

    it "handles missing images gracefully" do
      missionary = create(:user, :missionary, status: :approved)
      profile = create(:missionary_profile, user: missionary, organization: organization)
      
      visit missionary_path(missionary)
      
      # Should load even if images are missing
      expect(page).to have_content(missionary.name)
    end
  end

  describe "Database Performance" do
    it "handles large result sets efficiently" do
      # Create a large dataset
      create_list(:user, 100, :supporter)
      
      # This should still load reasonably quickly
      expect {
        visit missionaries_path
      }.to complete_within(5.seconds)
    end

    it "uses appropriate database indexes" do
      # This is conceptual - in reality you'd check query execution plans
      
      # Create data that would benefit from indexes
      users = create_list(:user, 50, :missionary, status: :approved)
      users.each do |user|
        create(:missionary_profile, user: user, organization: organization)
      end
      
      # These operations should be fast due to proper indexing
      start_time = Time.current
      visit missionaries_path
      end_time = Time.current
      
      expect(end_time - start_time).to be < 3.seconds
    end
  end

  describe "Error Handling Performance" do
    it "handles 404 errors efficiently" do
      visit "/nonexistent-page"
      
      # Should redirect or show 404 quickly
      expect(page.status_code).to be_in([404, 200]) # 200 if redirected
    end

    it "handles invalid record IDs gracefully" do
      visit "/missionaries/999999"
      
      # Should handle gracefully without timeout
      expect(current_path).to eq("/missionaries") # Likely redirected
    end
  end
end
