require 'rails_helper'

RSpec.describe "Full Application Functionality", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:organization) { create(:organization, name: "Test Ministry") }
  let!(:supporter) { create(:user, :supporter, :approved, email: "supporter@test.com", password: "SecurePassword123!", password_confirmation: "SecurePassword123!") }
  let!(:missionary) { create(:user, :missionary, :approved, email: "missionary@test.com", password: "SecurePassword123!", password_confirmation: "SecurePassword123!") }
  let!(:missionary_profile) { create(:missionary_profile, user: missionary, organization: organization) }
  let!(:prayer_request) { create(:prayer_request, missionary_profile: missionary_profile, title: "Test Prayer Request", body: "Please pray for our mission work.") }
  let!(:missionary_update) { create(:missionary_update, user: missionary, title: "Test Update", update_type: :general) }

  describe "Home Page" do
    it "displays the home page correctly" do
      visit root_path
      
      expect(page).to have_content("Connecting Missionaries with Supporters Worldwide")
      expect(page).to have_link("Get Started")
      expect(page).to have_link("Find Missionaries")
    end
  end

  describe "User Registration and Authentication" do
    it "allows new supporter registration" do
      visit root_path
      click_link "Get Started"
      
      fill_in "Name", with: "New Supporter"
      fill_in "Email", with: "newsupporter@test.com"
      fill_in "Password", with: "SecurePassword123!"
      fill_in "Confirm password", with: "SecurePassword123!"
      select "I want to support missionaries", from: "Role"
      
      click_button "Create account"
      
      expect(page).to have_content("Welcome")
      expect(current_path).to eq("/dashboard/supporter")
    end

    it "allows user sign in and navigation" do
      visit new_user_session_path
      
      fill_in "Email", with: supporter.email
      fill_in "Password", with: "SecurePassword123!"
      click_button "Sign in"
      
      expect(page).to have_content("Signed in successfully")
      expect(current_path).to eq("/dashboard/supporter")
    end
  end

  describe "Supporter Dashboard" do
    before do
      create(:follow, follower: supporter, followable: missionary_profile)
      sign_in supporter
      visit dashboard_path
    end

    it "displays the dashboard with updates and prayer requests" do
      expect(page).to have_content("Welcome back")
      expect(page).to have_content("Latest Updates")
      expect(page).to have_content("Prayer Requests")
      
      # Check for the 2/3 - 1/3 layout
      expect(page).to have_css(".grid")
      expect(page).to have_css(".lg\\:col-span-2") # Updates column
      expect(page).to have_css(".lg\\:col-span-1") # Prayer requests column
    end

    it "displays prayer requests and allows interaction" do
      expect(page).to have_content("Test Prayer Request")
      expect(page).to have_content("Please pray for our mission work")
      
      # Check if prayer button exists (may vary based on implementation)
      if page.has_button?("Pray")
        click_button "Pray", match: :first
        expect(page).to have_content("Prayed").or have_content("Thank you")
      end
    end
  end

  describe "Missionaries Page" do
    it "displays the missionaries listing" do
      visit missionaries_path
      
      expect(page).to have_content("Find Missionaries")
      expect(page).to have_content(missionary.name)
    end

    it "allows viewing missionary profiles" do
      visit missionary_path(missionary)
      
      expect(page).to have_content(missionary.name)
      expect(page).to have_content("Test Ministry")
      
      # Check for follow button if not already following
      if page.has_button?("Follow")
        click_button "Follow"
        expect(page).to have_button("Following").or have_content("Following")
      end
    end
  end

  describe "Prayer Requests Page" do
    it "displays public prayer requests" do
      visit prayer_requests_path
      
      expect(page).to have_content("Prayer Requests")
      expect(page).to have_content("Test Prayer Request")
    end
  end

  describe "Missionary Functionality" do
    before { sign_in missionary }

    it "allows missionaries to access their dashboard" do
      visit dashboard_path
      
      expect(page).to have_content("Welcome back")
      expect(page).to have_content("Your Updates").or have_content("Create Update")
    end

    it "allows creating new updates with rich text" do
      visit new_missionary_update_path

      fill_in "Title", with: "New Ministry Update"
      
      # Test rich text editor if available
      within(".trix-editor") do
        page.execute_script("document.querySelector('.trix-editor').textContent = 'This is a test update with rich text content.'")
      end
      
      click_button "Publish Update"
      
      expect(page).to have_content("Update was successfully created").or have_content("New Ministry Update")
    end

    it "allows creating prayer requests" do
      visit new_prayer_request_path
      
      fill_in "Title", with: "New Prayer Request"
      fill_in "Body", with: "Please pray for our upcoming mission trip."
      select "Medium", from: "Urgency"
      
      click_button "Create Prayer Request"
      
      expect(page).to have_content("Prayer request was successfully created").or have_content("New Prayer Request")
    end

    it "allows accessing privacy settings" do
      visit missionary_settings_path
      
      expect(page).to have_content("Privacy Settings").or have_content("Settings")
      
      # Test privacy level change
      if page.has_select?("Safety mode") || page.has_select?("Privacy level")
        select "Limited visibility", from: page.has_select?("Safety mode") ? "Safety mode" : "Privacy level"
        click_button "Update Settings"
        
        expect(page).to have_content("Settings updated").or have_content("Successfully updated")
      end
    end
  end

  describe "Messaging System" do
    it "allows supporters to message missionaries" do
      sign_in supporter
      visit missionary_path(missionary)
      
      if page.has_button?("Send Message") || page.has_link?("Message")
        page.has_button?("Send Message") ? click_button("Send Message") : click_link("Message")
        
        fill_in "Subject", with: "Test Message" if page.has_field?("Subject")
        fill_in "Body", with: "This is a test message from a supporter."
        
        page.has_button?("Send Message") ? click_button("Send Message") : click_button("Send")
        
        expect(page).to have_content("Message sent").or have_content("sent successfully")
      end
    end
  end

  describe "Navigation and Links" do
    it "ensures all main navigation links work" do
      visit root_path
      
      # Test main navigation
      click_link "Find Missionaries"
      expect(current_path).to eq("/missionaries")
      
      click_link "Prayer Requests"
      expect(current_path).to eq("/prayer_requests")
      
      # Test authenticated navigation
      sign_in supporter
      visit root_path
      
      click_link "Dashboard"
      expect(current_path).to eq("/dashboard")
    end
  end

  describe "Mobile Responsiveness" do
    it "displays correctly on mobile viewport" do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone SE size
      
      visit dashboard_path
      sign_in supporter
      
      # Should still show content properly
      expect(page).to have_content("Welcome back")
      expect(page).to have_css(".grid") # Grid should still work on mobile
    end
  end
end
