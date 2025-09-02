require 'rails_helper'

RSpec.describe "Missionary Features", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:organization) { create(:organization, name: "Global Missions") }
  let!(:missionary) { create(:user, :missionary, status: :approved, name: "John Missionary") }
  let!(:missionary_profile) { create(:missionary_profile, user: missionary, organization: organization) }
  let!(:supporter) { create(:user, :supporter, name: "Jane Supporter") }

  describe "Missionary Profile Management" do
    before { sign_in(missionary) }

    it "allows missionaries to view their profile" do
      visit missionary_path(missionary)
      
      expect(page).to have_content(missionary.name)
      expect(page).to have_content(missionary_profile.bio) if missionary_profile.bio.present?
      expect(page).to have_content(organization.name)
    end

    it "allows missionaries to edit their profile" do
      visit edit_profile_path
      
      fill_in "Bio", with: "Updated bio content"
      fill_in "Mission focus", with: "Church planting in Southeast Asia"
      
      click_button "Update Profile"
      
      expect(page).to have_content("Profile updated successfully")
      
      missionary_profile.reload
      expect(missionary_profile.bio).to eq("Updated bio content")
      expect(missionary_profile.mission_focus).to eq("Church planting in Southeast Asia")
    end

    it "shows validation errors for invalid profile data" do
      visit edit_profile_path
      
      fill_in "Bio", with: "" # Clear required field
      
      click_button "Update Profile"
      
      expect(page).to have_content("Bio can't be blank")
    end
  end

  describe "Missionary Updates" do
    before { sign_in(missionary) }

    it "allows missionaries to create updates" do
      visit new_update_path
      
      fill_in "Title", with: "Ministry Update from the Field"
      fill_in "Content", with: "God is doing amazing things here! We've seen 15 new believers this month."
      select "General Update", from: "Update type"
      
      click_button "Create Update"
      
      expect(page).to have_content("Update created successfully")
      expect(page).to have_content("Ministry Update from the Field")
      
      update = MissionaryUpdate.last
      expect(update.title).to eq("Ministry Update from the Field")
      expect(update.missionary_profile).to eq(missionary_profile)
    end

    it "displays missionary's updates on their profile" do
      update = create(:missionary_update, 
        missionary_profile: missionary_profile,
        title: "Recent Ministry Update",
        content: "Great things happening!",
        created_at: 1.day.ago
      )
      
      visit missionary_path(missionary)
      
      expect(page).to have_content("Recent Ministry Update")
      expect(page).to have_content("Great things happening!")
      expect(page).to have_content("1 day ago")
    end

    it "allows missionaries to edit their updates" do
      update = create(:missionary_update, missionary_profile: missionary_profile)
      
      visit edit_update_path(update)
      
      fill_in "Title", with: "Updated Title"
      fill_in "Content", with: "Updated content"
      
      click_button "Update Post"
      
      expect(page).to have_content("Update modified successfully")
      expect(page).to have_content("Updated Title")
      expect(page).to have_content("Updated content")
    end

    it "allows missionaries to delete their updates" do
      update = create(:missionary_update, missionary_profile: missionary_profile)
      
      visit missionary_path(missionary)
      
      click_button "Delete Update"
      
      expect(page).to have_content("Update deleted successfully")
      expect(MissionaryUpdate.exists?(update.id)).to be_false
    end
  end

  describe "Prayer Requests" do
    before { sign_in(missionary) }

    it "allows missionaries to create prayer requests" do
      visit new_prayer_request_path
      
      fill_in "Title", with: "Pray for Health"
      fill_in "Content", with: "Please pray for my health as I recover from illness"
      select "High", from: "Urgency"
      
      click_button "Create Prayer Request"
      
      expect(page).to have_content("Prayer request created successfully")
      
      prayer_request = PrayerRequest.last
      expect(prayer_request.title).to eq("Pray for Health")
      expect(prayer_request.urgency).to eq("high")
      expect(prayer_request.missionary_profile).to eq(missionary_profile)
    end

    it "displays prayer requests on missionary profile" do
      prayer_request = create(:prayer_request,
        missionary_profile: missionary_profile,
        title: "Pray for Ministry",
        urgency: :medium
      )
      
      visit missionary_path(missionary)
      
      expect(page).to have_content("Pray for Ministry")
      expect(page).to have_content("MEDIUM")
    end

    it "shows prayer count for requests" do
      prayer_request = create(:prayer_request, missionary_profile: missionary_profile)
      create(:prayer_action, prayer_request: prayer_request, user: supporter)
      
      visit missionary_path(missionary)
      
      expect(page).to have_content("1 prayer")
    end

    it "allows missionaries to edit prayer requests" do
      prayer_request = create(:prayer_request, missionary_profile: missionary_profile)
      
      visit edit_prayer_request_path(prayer_request)
      
      fill_in "Title", with: "Updated Prayer Request"
      select "Low", from: "Urgency"
      
      click_button "Update Prayer Request"
      
      expect(page).to have_content("Prayer request updated successfully")
      expect(page).to have_content("Updated Prayer Request")
    end
  end

  describe "Following System" do
    before { sign_in(supporter) }

    it "allows supporters to follow missionaries" do
      visit missionary_path(missionary)
      
      click_button "Follow"
      
      expect(page).to have_content("Now following #{missionary.name}")
      expect(page).to have_button("Unfollow")
      
      follow = Follow.find_by(follower: supporter, missionary_profile: missionary_profile)
      expect(follow).to be_present
    end

    it "allows supporters to unfollow missionaries" do
      create(:follow, follower: supporter, missionary_profile: missionary_profile)
      
      visit missionary_path(missionary)
      
      click_button "Unfollow"
      
      expect(page).to have_content("Unfollowed #{missionary.name}")
      expect(page).to have_button("Follow")
      
      expect(Follow.exists?(follower: supporter, missionary_profile: missionary_profile)).to be_false
    end

    it "shows follower count on missionary profile" do
      create(:follow, follower: supporter, missionary_profile: missionary_profile)
      other_supporter = create(:user, :supporter)
      create(:follow, follower: other_supporter, missionary_profile: missionary_profile)
      
      visit missionary_path(missionary)
      
      expect(page).to have_content("2 followers")
    end
  end

  describe "Missionary Discovery" do
    let!(:missionary2) { create(:user, :missionary, status: :approved, name: "Bob Missionary") }
    let!(:missionary_profile2) { create(:missionary_profile, user: missionary2, organization: organization) }
    let!(:inactive_missionary) { create(:user, :missionary, status: :pending) }

    before { sign_in(supporter) }

    it "displays list of approved missionaries" do
      visit missionaries_path
      
      expect(page).to have_content("Find Missionaries")
      expect(page).to have_content(missionary.name)
      expect(page).to have_content(missionary2.name)
      expect(page).not_to have_content(inactive_missionary.name)
    end

    it "allows filtering missionaries by organization" do
      other_org = create(:organization, name: "Asian Missions")
      other_missionary = create(:user, :missionary, status: :approved)
      create(:missionary_profile, user: other_missionary, organization: other_org)
      
      visit missionaries_path
      
      select "Global Missions", from: "Organization"
      click_button "Filter"
      
      expect(page).to have_content(missionary.name)
      expect(page).to have_content(missionary2.name)
      expect(page).not_to have_content(other_missionary.name)
    end

    it "allows searching missionaries by name" do
      visit missionaries_path
      
      fill_in "Search", with: "John"
      click_button "Search"
      
      expect(page).to have_content(missionary.name)
      expect(page).not_to have_content(missionary2.name)
    end
  end

  describe "Privacy and Security" do
    it "prevents access to missionary features for unapproved missionaries" do
      pending_missionary = create(:user, :missionary, status: :pending)
      sign_in(pending_missionary)
      
      visit new_update_path
      
      expect(page).to have_content("Your account is pending approval")
      expect(current_path).to eq(dashboard_path)
    end

    it "prevents supporters from accessing missionary-only features" do
      sign_in(supporter)
      
      visit new_update_path
      
      expect(page).to have_content("Not authorized")
      expect(current_path).to eq(dashboard_path)
    end

    it "prevents missionaries from editing other missionaries' content" do
      other_missionary = create(:user, :missionary, status: :approved)
      other_profile = create(:missionary_profile, user: other_missionary, organization: organization)
      update = create(:missionary_update, missionary_profile: other_profile)
      
      sign_in(missionary)
      
      visit edit_update_path(update)
      
      expect(page).to have_content("Not authorized")
    end
  end
end
