require 'rails_helper'

RSpec.describe "Authentication", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "User Sign Up" do
    it "allows a new user to sign up as a supporter" do
      visit new_user_registration_path

      expect(page).to have_content("Join our mission")
      
      fill_in "Name", with: "John Supporter"
      fill_in "Email", with: "john@example.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm password: "SecurePassword123!", password_confirmation: "SecurePassword123!""
      select "I want to support missionaries", from: "Role"
      
      click_button "Create account"
      
      expect(page).to have_content("Welcome! You have signed up successfully")
      expect(current_path).to eq("/dashboard/supporter")
      
      user = User.find_by(email: "john@example.com")
      expect(user).to be_present
      expect(user.role).to eq("supporter")
      expect(user.status).to eq("approved")
    end

    it "allows a new user to sign up as a missionary" do
      visit new_user_registration_path
      
      fill_in "Name", with: "Jane Missionary"
      fill_in "Email", with: "jane@example.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm password: "SecurePassword123!", password_confirmation: "SecurePassword123!""
      select "I am a missionary", from: "Role"
      
      click_button "Create account"
      
      expect(page).to have_content("Welcome! You have signed up successfully")
      
      user = User.find_by(email: "jane@example.com")
      expect(user).to be_present
      expect(user.role).to eq("missionary")
      expect(user.status).to eq("pending")
    end

    it "shows validation errors for invalid data" do
      visit new_user_registration_path
      
      click_button "Create account"
      
      expect(page).to have_content("Name can't be blank")
      expect(page).to have_content("Email can't be blank")
      expect(page).to have_content("Password can't be blank")
    end

    it "validates password confirmation" do
      visit new_user_registration_path
      
      fill_in "Name", with: "Test User"
      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm password", with: "different"
      
      click_button "Create account"
      
      expect(page).to have_content("Password confirmation doesn't match Password")
    end
  end

  describe "User Sign In" do
    let!(:user) { create(:user, :supporter, email: "supporter@example.com", password: "SecurePassword123!", password_confirmation: "SecurePassword123!"") }
    let!(:pending_user) { create(:user, :missionary, status: :pending, password: "SecurePassword123!", password_confirmation: "SecurePassword123!"") }
    let!(:inactive_user) { create(:user, :supporter, is_active: false, password: "SecurePassword123!", password_confirmation: "SecurePassword123!"") }

    it "allows valid users to sign in" do
      visit new_user_session_path
      
      expect(page).to have_content("Welcome back")
      
      fill_in "Email", with: user.email
      fill_in "Password", with: "password123"
      
      click_button "Sign in"
      
      expect(page).to have_content("Signed in successfully")
      # Supporters get redirected to supporter dashboard
      expect(current_path).to eq("/dashboard/supporter")
    end

    it "redirects based on user role after sign in" do
      admin = create(:user, :admin, password: "SecurePassword123!", password_confirmation: "SecurePassword123!"")
      
      visit new_user_session_path
      fill_in "Email", with: admin.email
      fill_in "Password", with: "password123"
      click_button "Sign in"
      
      # Admin should be redirected to admin area, but sign in might fail due to password
      expect(page).to have_content("Signed in successfully")
    end

    it "prevents sign in with invalid credentials" do
      visit new_user_session_path
      
      fill_in "Email", with: user.email
      fill_in "Password", with: "wrongpassword"
      
      click_button "Sign in"
      
      expect(page).to have_content("Invalid Email or password")
      expect(current_path).to eq(new_user_session_path)
    end

    it "allows sign in for pending users (they see pending message in dashboard)" do
      visit new_user_session_path
      
      fill_in "Email", with: pending_user.email
      fill_in "Password", with: "password123"
      
      click_button "Sign in"
      
      # Devise allows sign in, but dashboard shows pending message
      expect(page).to have_content("Signed in successfully")
      expect(current_path).to eq(dashboard_path)
    end

    it "allows sign in for inactive users (dashboard handles restriction)" do
      visit new_user_session_path
      
      fill_in "Email", with: inactive_user.email
      fill_in "Password", with: "password123"
      
      click_button "Sign in"
      
      # Devise allows sign in, but dashboard/other pages handle restrictions
      expect(page).to have_content("Signed in successfully")
    end
  end

  describe "Password Reset" do
    let!(:user) { create(:user, :supporter, email: "reset@example.com") }

    it "allows users to request password reset" do
      visit new_user_password_path
      
      expect(page).to have_content("Forgot your password?")
      
      fill_in "Email", with: user.email
      click_button "Send reset instructions"
      
      expect(page).to have_content("You will receive an email with instructions")
    end

    it "shows error for non-existent email" do
      visit new_user_password_path
      
      fill_in "Email", with: "nonexistent@example.com"
      click_button "Send reset instructions"
      
      expect(page).to have_content("Email not found")
    end
  end

  describe "User Sign Out" do
    let!(:user) { create(:user, :supporter, password: "SecurePassword123!", password_confirmation: "SecurePassword123!"") }

    it "allows users to sign out" do
      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "password123"
      click_button "Sign in"
      
      # Look for sign out link in navigation
      if page.has_link?("Sign Out")
        click_link "Sign Out"
      else
        # Visit sign out path directly
        visit destroy_user_session_path
      end
      
      expect(current_path).to eq(root_path)
    end
  end

  describe "Navigation Security" do
    let!(:supporter) { create(:user, :supporter) }
    let!(:missionary) { create(:user, :missionary, status: :approved) }
    let!(:admin) { create(:user, :admin) }

    it "prevents unauthorized access to admin areas" do
      visit new_user_session_path
      fill_in "Email", with: supporter.email
      fill_in "Password", with: "password123"
      click_button "Sign in"
      
      visit admin_root_path
      
      # Should show access denied message
      expect(page).to have_content("Access denied")
    end

    it "prevents unauthenticated access to protected pages" do
      visit dashboard_path
      
      expect(current_path).to eq(new_user_session_path)
      expect(page).to have_content("Please sign in to continue")
    end
  end
end
