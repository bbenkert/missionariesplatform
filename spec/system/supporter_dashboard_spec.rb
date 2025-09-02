require 'rails_helper'

RSpec.describe "Supporter Dashboard", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:organization) { create(:organization, name: "Global Missions") }
  let!(:supporter) { create(:user, :supporter, name: "John Supporter") }
  let!(:missionary1) { create(:user, :missionary, status: :approved, name: "Jane Missionary") }
  let!(:missionary2) { create(:user, :missionary, status: :approved, name: "Bob Missionary") }
  let!(:missionary_profile1) { create(:missionary_profile, user: missionary1, organization: organization) }
  let!(:missionary_profile2) { create(:missionary_profile, user: missionary2, organization: organization) }

  before do
    sign_in(supporter)
  end

  describe "Dashboard Overview" do
    let!(:follow1) { create(:follow, follower: supporter, missionary_profile: missionary_profile1) }
    let!(:follow2) { create(:follow, follower: supporter, missionary_profile: missionary_profile2) }
    let!(:update1) { create(:missionary_update, missionary_profile: missionary_profile1, created_at: 1.day.ago) }
    let!(:update2) { create(:missionary_update, missionary_profile: missionary_profile2, created_at: 2.days.ago) }
    let!(:prayer_request1) { create(:prayer_request, missionary_profile: missionary_profile1, urgency: :high) }
    let!(:prayer_request2) { create(:prayer_request, missionary_profile: missionary_profile2, urgency: :medium) }

    it "displays welcome message and user name" do
      visit dashboard_path
      
      expect(page).to have_content("Welcome back, John Supporter!")
      expect(page).to have_content("Supporter Dashboard")
    end

    it "shows statistics cards with correct counts" do
      visit dashboard_path
      
      within("[data-testid='stats-following']") do
        expect(page).to have_content("2")
        expect(page).to have_content("Following")
      end
      
      within("[data-testid='stats-updates']") do
        expect(page).to have_content("2")
        expect(page).to have_content("New Updates")
      end
      
      within("[data-testid='stats-prayers']") do
        expect(page).to have_content("2")
        expect(page).to have_content("Prayer Requests")
      end
    end

    it "displays recent updates from followed missionaries" do
      visit dashboard_path
      
      within("[data-testid='recent-updates']") do
        expect(page).to have_content("Recent Updates")
        expect(page).to have_content(missionary1.name)
        expect(page).to have_content(missionary2.name)
        expect(page).to have_content(update1.title)
        expect(page).to have_content(update2.title)
      end
    end

    it "displays updates in chronological order (newest first)" do
      visit dashboard_path
      
      updates_section = find("[data-testid='recent-updates']")
      update_elements = updates_section.all("[data-testid='update-item']")
      
      expect(update_elements.first).to have_content(update1.title) # 1 day ago (newer)
      expect(update_elements.second).to have_content(update2.title) # 2 days ago (older)
    end

    it "shows prayer requests sidebar" do
      visit dashboard_path
      
      within("[data-testid='prayer-requests-sidebar']") do
        expect(page).to have_content("Prayer Requests")
        expect(page).to have_content(prayer_request1.title)
        expect(page).to have_content(prayer_request2.title)
      end
    end

    it "displays urgency badges correctly" do
      visit dashboard_path
      
      within("[data-testid='prayer-requests-sidebar']") do
        high_urgency_badge = find("[data-testid='urgency-high']")
        expect(high_urgency_badge).to have_content("HIGH")
        expect(high_urgency_badge[:class]).to include("bg-red-100", "text-red-800")
        
        medium_urgency_badge = find("[data-testid='urgency-medium']")
        expect(medium_urgency_badge).to have_content("MEDIUM")
        expect(medium_urgency_badge[:class]).to include("bg-yellow-100", "text-yellow-800")
      end
    end
  end

  describe "Prayer Request Interactions" do
    let!(:follow) { create(:follow, follower: supporter, missionary_profile: missionary_profile1) }
    let!(:prayer_request) { create(:prayer_request, missionary_profile: missionary_profile1, urgency: :high) }

    it "allows supporters to pray for requests via AJAX", js: true do
      visit dashboard_path
      
      within("[data-testid='prayer-requests-sidebar']") do
        prayer_button = find("[data-testid='pray-button']")
        
        expect(prayer_button).to have_content("Pray")
        
        prayer_button.click
        
        # Wait for AJAX to complete
        expect(page).to have_content("Prayed", wait: 5)
        
        # Verify prayer action was created
        prayer_action = PrayerAction.find_by(user: supporter, prayer_request: prayer_request)
        expect(prayer_action).to be_present
      end
    end

    it "shows prayer count updates", js: true do
      create(:prayer_action, user: missionary1, prayer_request: prayer_request)
      
      visit dashboard_path
      
      within("[data-testid='prayer-requests-sidebar']") do
        expect(page).to have_content("1 prayer")
        
        find("[data-testid='pray-button']").click
        
        # Wait for count update
        expect(page).to have_content("2 prayers", wait: 5)
      end
    end
  end

  describe "Empty States" do
    it "shows empty state when not following any missionaries" do
      visit dashboard_path
      
      within("[data-testid='recent-updates']") do
        expect(page).to have_content("No updates yet")
        expect(page).to have_content("Start following missionaries to see their updates here")
        expect(page).to have_link("Find Missionaries", href: missionaries_path)
      end
    end

    it "shows empty state for prayer requests when not following anyone" do
      visit dashboard_path
      
      within("[data-testid='prayer-requests-sidebar']") do
        expect(page).to have_content("No prayer requests")
        expect(page).to have_content("Follow missionaries to see their prayer requests")
      end
    end
  end

  describe "Navigation Links" do
    it "provides navigation to missionaries page" do
      visit dashboard_path
      
      click_link "Find Missionaries"
      
      expect(current_path).to eq(missionaries_path)
    end

    it "provides navigation to individual missionary profiles" do
      create(:follow, follower: supporter, missionary_profile: missionary_profile1)
      create(:missionary_update, missionary_profile: missionary_profile1)
      
      visit dashboard_path
      
      within("[data-testid='recent-updates']") do
        click_link missionary1.name
      end
      
      expect(current_path).to eq(missionary_path(missionary1))
    end
  end

  describe "Responsive Design" do
    it "displays correctly on mobile viewport", mobile: true do
      visit dashboard_path
      
      # Test mobile-specific elements
      expect(page).to have_css("[data-testid='stats-following']")
      expect(page).to have_css("[data-testid='recent-updates']")
      expect(page).to have_css("[data-testid='prayer-requests-sidebar']")
    end
  end

  describe "Real-time Updates" do
    let!(:follow) { create(:follow, follower: supporter, missionary_profile: missionary_profile1) }

    it "updates counts when new content is added", js: true do
      visit dashboard_path
      
      # Simulate new update being added (in real app this would be via WebSocket/ActionCable)
      create(:missionary_update, missionary_profile: missionary_profile1)
      
      # Refresh to see new count
      visit dashboard_path
      
      within("[data-testid='stats-updates']") do
        expect(page).to have_content("1")
      end
    end
  end
end
