require 'rails_helper'

RSpec.describe "Admin Features", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:admin) { create(:user, :admin, name: "Admin User") }
  let!(:organization) { create(:organization, name: "Global Missions") }
  let!(:pending_missionary) { create(:user, :missionary, status: :pending, name: "Pending Missionary") }
  let!(:approved_missionary) { create(:user, :missionary, status: :approved, name: "Approved Missionary") }
  let!(:supporter) { create(:user, :supporter, name: "Regular Supporter") }

  describe "Admin Dashboard Access" do
    it "allows admins to access admin dashboard" do
      sign_in(admin)
      
      visit admin_dashboard_path
      
      expect(page).to have_content("Admin Dashboard")
      expect(page).to have_content("Welcome, #{admin.name}")
    end

    it "prevents non-admins from accessing admin areas" do
      sign_in(supporter)
      
      visit admin_dashboard_path
      
      expect(page).to have_content("Not authorized")
      expect(current_path).to eq(dashboard_path)
    end

    it "redirects admins to admin dashboard after login" do
      visit new_user_session_path
      
      fill_in "Email", with: admin.email
      fill_in "Password", with: "password123"
      click_button "Sign In"
      
      expect(current_path).to eq(admin_dashboard_path)
    end
  end

  describe "User Management" do
    before { sign_in(admin) }

    it "displays all users in admin users index" do
      visit admin_users_path
      
      expect(page).to have_content("User Management")
      expect(page).to have_content(admin.name)
      expect(page).to have_content(pending_missionary.name)
      expect(page).to have_content(approved_missionary.name)
      expect(page).to have_content(supporter.name)
    end

    it "shows user status and roles correctly" do
      visit admin_users_path
      
      within("tr", text: pending_missionary.name) do
        expect(page).to have_content("pending")
        expect(page).to have_content("missionary")
      end
      
      within("tr", text: supporter.name) do
        expect(page).to have_content("approved")
        expect(page).to have_content("supporter")
      end
    end

    it "allows filtering users by status" do
      visit admin_users_path
      
      select "Pending", from: "Status"
      click_button "Filter"
      
      expect(page).to have_content(pending_missionary.name)
      expect(page).not_to have_content(supporter.name)
    end

    it "allows filtering users by role" do
      visit admin_users_path
      
      select "Missionary", from: "Role"
      click_button "Filter"
      
      expect(page).to have_content(pending_missionary.name)
      expect(page).to have_content(approved_missionary.name)
      expect(page).not_to have_content(supporter.name)
    end

    it "allows searching users by name or email" do
      visit admin_users_path
      
      fill_in "Search", with: "Pending"
      click_button "Search"
      
      expect(page).to have_content(pending_missionary.name)
      expect(page).not_to have_content(supporter.name)
    end
  end

  describe "User Approval System" do
    before { sign_in(admin) }

    it "allows admins to approve pending missionaries" do
      visit admin_users_path
      
      within("tr", text: pending_missionary.name) do
        click_button "Approve"
      end
      
      expect(page).to have_content("User approved successfully")
      
      pending_missionary.reload
      expect(pending_missionary.status).to eq("approved")
    end

    it "allows admins to reject pending users" do
      visit admin_users_path
      
      within("tr", text: pending_missionary.name) do
        click_button "Reject"
      end
      
      expect(page).to have_content("User rejected successfully")
      
      pending_missionary.reload
      expect(pending_missionary.status).to eq("rejected")
    end

    it "sends notification email when user is approved", email: true do
      visit admin_users_path
      
      within("tr", text: pending_missionary.name) do
        click_button "Approve"
      end
      
      # Check that email job was enqueued
      expect(NotificationJob).to have_been_enqueued.with(
        pending_missionary.id, 
        'approval_notification'
      )
    end

    it "prevents approval of already approved users" do
      visit admin_users_path
      
      within("tr", text: approved_missionary.name) do
        expect(page).not_to have_button("Approve")
        expect(page).to have_content("approved")
      end
    end
  end

  describe "User Account Management" do
    before { sign_in(admin) }

    it "allows admins to deactivate user accounts" do
      visit admin_user_path(supporter)
      
      click_button "Deactivate Account"
      
      expect(page).to have_content("User account deactivated")
      
      supporter.reload
      expect(supporter.is_active).to be_false
    end

    it "allows admins to reactivate user accounts" do
      supporter.update!(is_active: false)
      
      visit admin_user_path(supporter)
      
      click_button "Reactivate Account"
      
      expect(page).to have_content("User account reactivated")
      
      supporter.reload
      expect(supporter.is_active).to be_true
    end

    it "shows user activity statistics" do
      missionary_profile = create(:missionary_profile, user: approved_missionary, organization: organization)
      create_list(:missionary_update, 3, missionary_profile: missionary_profile)
      create_list(:prayer_request, 2, missionary_profile: missionary_profile)
      
      visit admin_user_path(approved_missionary)
      
      expect(page).to have_content("3 updates")
      expect(page).to have_content("2 prayer requests")
    end

    it "displays user registration and login history" do
      supporter.update!(
        created_at: 1.month.ago,
        current_sign_in_at: 1.day.ago,
        last_sign_in_at: 3.days.ago
      )
      
      visit admin_user_path(supporter)
      
      expect(page).to have_content("Member since")
      expect(page).to have_content("Last login")
      expect(page).to have_content("Previous login")
    end
  end

  describe "Organization Management" do
    let!(:org_admin) { create(:user, :organization_admin, name: "Org Admin") }
    
    before do
      org_admin.organization = organization
      org_admin.save!
      sign_in(admin)
    end

    it "allows admins to view all organizations" do
      other_org = create(:organization, name: "Asian Missions")
      
      visit admin_organizations_path
      
      expect(page).to have_content("Organization Management")
      expect(page).to have_content("Global Missions")
      expect(page).to have_content("Asian Missions")
    end

    it "shows organization statistics" do
      missionary_profile = create(:missionary_profile, user: approved_missionary, organization: organization)
      
      visit admin_organizations_path
      
      within("tr", text: organization.name) do
        expect(page).to have_content("1 missionary")
        expect(page).to have_content("1 admin")
      end
    end

    it "allows creating new organizations" do
      visit admin_organizations_path
      
      click_link "New Organization"
      
      fill_in "Name", with: "European Missions"
      fill_in "Description", with: "Reaching Europe for Christ"
      
      click_button "Create Organization"
      
      expect(page).to have_content("Organization created successfully")
      expect(page).to have_content("European Missions")
    end
  end

  describe "Content Moderation" do
    let!(:missionary_profile) { create(:missionary_profile, user: approved_missionary, organization: organization) }
    let!(:update_with_issues) { create(:missionary_update, missionary_profile: missionary_profile, title: "Problematic Content") }
    let!(:prayer_request) { create(:prayer_request, missionary_profile: missionary_profile) }

    before { sign_in(admin) }

    it "allows admins to view all missionary updates" do
      visit admin_updates_path
      
      expect(page).to have_content("Content Moderation")
      expect(page).to have_content("Problematic Content")
      expect(page).to have_content(approved_missionary.name)
    end

    it "allows admins to edit inappropriate content" do
      visit admin_update_path(update_with_issues)
      
      click_link "Edit Content"
      
      fill_in "Title", with: "Moderated Title"
      fill_in "Content", with: "Moderated content"
      
      click_button "Update Content"
      
      expect(page).to have_content("Content updated successfully")
      expect(page).to have_content("Moderated Title")
    end

    it "allows admins to delete inappropriate content" do
      visit admin_updates_path
      
      within("tr", text: "Problematic Content") do
        click_button "Delete"
      end
      
      expect(page).to have_content("Content deleted successfully")
      expect(MissionaryUpdate.exists?(update_with_issues.id)).to be_false
    end

    it "logs moderation actions for audit trail" do
      visit admin_update_path(update_with_issues)
      
      click_button "Delete Content"
      
      # Verify audit log entry was created
      expect(page).to have_content("Action logged for audit")
    end
  end

  describe "System Statistics" do
    before { sign_in(admin) }

    it "displays platform statistics on admin dashboard" do
      visit admin_dashboard_path
      
      expect(page).to have_content("Platform Statistics")
      expect(page).to have_content("Total Users")
      expect(page).to have_content("Active Missionaries")
      expect(page).to have_content("Pending Approvals")
      expect(page).to have_content("Organizations")
    end

    it "shows recent user registrations" do
      recent_user = create(:user, :supporter, created_at: 1.hour.ago, name: "Recent User")
      
      visit admin_dashboard_path
      
      within("[data-testid='recent-registrations']") do
        expect(page).to have_content("Recent Registrations")
        expect(page).to have_content(recent_user.name)
      end
    end

    it "displays pending approval count" do
      create(:user, :missionary, status: :pending)
      create(:user, :missionary, status: :pending)
      
      visit admin_dashboard_path
      
      within("[data-testid='pending-approvals']") do
        expect(page).to have_content("3") # 2 new + 1 existing
      end
    end
  end

  describe "Email Management" do
    before { sign_in(admin) }

    it "shows email log and delivery status" do
      email_log = create(:email_log, 
        recipient: supporter.email,
        subject: "Test Email",
        status: :delivered
      )
      
      visit admin_email_logs_path
      
      expect(page).to have_content("Email Management")
      expect(page).to have_content("Test Email")
      expect(page).to have_content("delivered")
    end

    it "allows resending failed emails" do
      failed_email = create(:email_log,
        recipient: supporter.email,
        status: :failed
      )
      
      visit admin_email_logs_path
      
      within("tr", text: failed_email.subject) do
        click_button "Resend"
      end
      
      expect(page).to have_content("Email queued for resend")
    end
  end

  describe "Security and Audit" do
    before { sign_in(admin) }

    it "logs admin actions for security audit" do
      visit admin_users_path
      
      within("tr", text: pending_missionary.name) do
        click_button "Approve"
      end
      
      # Check audit log was created
      visit admin_audit_logs_path
      
      expect(page).to have_content("User approved")
      expect(page).to have_content(admin.name)
      expect(page).to have_content(pending_missionary.name)
    end

    it "prevents admins from deleting their own accounts" do
      visit admin_user_path(admin)
      
      expect(page).not_to have_button("Delete Account")
      expect(page).to have_content("Cannot delete your own account")
    end

    it "requires confirmation for destructive actions" do
      visit admin_user_path(supporter)
      
      click_button "Delete Account"
      
      expect(page).to have_content("Are you sure you want to delete this account?")
    end
  end
end
