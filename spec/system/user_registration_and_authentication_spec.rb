require 'rails_helper'

RSpec.describe 'User Registration and Authentication', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'User Registration' do
    context 'successful supporter registration' do
    it 'allows a supporter to register and sign in' do
      visit new_user_registration_path        fill_in 'Full Name', with: 'John Supporter'
        fill_in 'Email address', with: 'john.supporter@example.com'
        choose 'Supporter'
        fill_in 'Password', with: 'SecurePassword123!'
        fill_in 'Confirm Password', with: 'SecurePassword123!'
        check 'I agree to the Terms of Service and Privacy Policy'

        click_button 'Create Account'

        expect(page).to have_content('Welcome to the missionary platform!')
        expect(page).to have_current_path(dashboard_path)

        # Verify user is signed in
        expect(page).to have_content('John Supporter')

        # Sign out
        click_link 'Sign Out'
        expect(page).to have_current_path(root_path)
      end
    end

    context 'successful missionary registration' do
    it 'allows a missionary to register with pending status' do
      visit new_user_registration_path        fill_in 'Full Name', with: 'Jane Missionary'
        fill_in 'Email address', with: 'jane.missionary@example.com'
        choose 'Missionary'
        fill_in 'Password', with: 'SecurePassword123!'
        fill_in 'Confirm Password', with: 'SecurePassword123!'
        check 'I agree to the Terms of Service and Privacy Policy'

        click_button 'Create Account'

        expect(page).to have_content('Welcome! Your missionary profile is pending approval.')
        expect(page).to have_current_path(dashboard_path)

        # Verify user is signed in
        expect(page).to have_content('Jane Missionary')
      end
    end

    context 'registration validation errors' do
      it 'shows validation errors for invalid data' do
        visit new_user_registration_path

        fill_in 'Full Name', with: ''
        fill_in 'Email address', with: 'invalid-email'
        fill_in 'Password', with: '123'
        fill_in 'Confirm Password', with: '456'
        uncheck 'I agree to the Terms of Service and Privacy Policy'

        click_button 'Create Account'

        expect(page).to have_content("can't be blank")
        expect(page).to have_content('is invalid')
        expect(page).to have_content('is too short')
        expect(page).to have_current_path(sign_up_path)
      end

      it 'shows error for duplicate email' do
        create(:user, email: 'existing@example.com')

        visit new_user_registration_path

        fill_in 'Full Name', with: 'John Doe'
        fill_in 'Email address', with: 'existing@example.com'
        choose 'Supporter'
        fill_in 'Password', with: 'SecurePassword123!'
        fill_in 'Confirm Password', with: 'SecurePassword123!'
        check 'I agree to the Terms of Service and Privacy Policy'

        click_button 'Create Account'

        expect(page).to have_content('has already been taken')
        expect(page).to have_current_path(sign_up_path)
      end
    end
  end

  describe 'User Sign In' do
    let!(:user) { create(:user, :supporter, name: 'John Doe', email: 'john@example.com', password: 'SecurePassword123!') }

    context 'successful sign in' do
      it 'allows user to sign in with correct credentials' do
        visit sign_in_path

        fill_in 'Email address', with: 'john@example.com'
        fill_in 'Password', with: 'SecurePassword123!'

        click_button 'Sign In'

        expect(page).to have_content('John Doe')
        expect(page).to have_current_path(dashboard_path)
      end

      it 'redirects already signed in user' do
        sign_in(user)
        visit sign_in_path

        expect(page).to have_current_path(dashboard_path)
      end
    end

    context 'failed sign in' do
      it 'shows error with invalid credentials' do
        visit sign_in_path

        fill_in 'Email address', with: 'john@example.com'
        fill_in 'Password', with: 'wrongpassword'

        click_button 'Sign In'

        expect(page).to have_content('Invalid email or password')
        expect(page).to have_current_path(sign_in_path)
      end

      it 'shows error with non-existent email' do
        visit sign_in_path

        fill_in 'Email address', with: 'nonexistent@example.com'
        fill_in 'Password', with: 'SecurePassword123!'

        click_button 'Sign In'

        expect(page).to have_content('Invalid email or password')
        expect(page).to have_current_path(sign_in_path)
      end
    end
  end

  describe 'Missionary Approval Flow' do
    let!(:missionary) { create(:user, :missionary, :pending, name: 'Jane Missionary', email: 'jane@example.com', password: 'SecurePassword123!') }
    let!(:admin) { create(:user, :admin, name: 'Admin User', email: 'admin@example.com', password: 'SecurePassword123!') }

    it 'allows admin to approve missionary' do
      # Sign in as admin
      visit sign_in_path
      fill_in 'Email address', with: 'admin@example.com'
      fill_in 'Password', with: 'SecurePassword123!'
      click_button 'Sign In'

      # Navigate to admin panel (assuming it exists)
      # This would need to be implemented based on your admin interface
      # For now, we'll test the approval via direct database update

      # Approve the missionary
      missionary.update(status: :approved)

      # Sign out admin and sign in as missionary
      click_link 'Sign Out'

      visit sign_in_path
      fill_in 'Email address', with: 'jane@example.com'
      fill_in 'Password', with: 'SecurePassword123!'
      click_button 'Sign In'

      # Should now be able to access missionary features
      expect(page).to have_content('Jane Missionary')
      expect(page).to have_current_path(dashboard_path)
    end
  end

  describe 'Password Reset Flow' do
    let!(:user) { create(:user, email: 'user@example.com') }

      it 'allows user to request password reset' do
        visit new_user_session_path      click_link 'Forgot your password?'

      fill_in 'Email address', with: 'user@example.com'
      click_button 'Send Reset Instructions'

      expect(page).to have_content('If an account with that email exists')
    end
  end

  describe 'Role-based Access Control' do
    let!(:supporter) { create(:user, :supporter, name: 'Supporter User', email: 'supporter@example.com', password: 'SecurePassword123!') }
    let!(:missionary) { create(:user, :missionary, :approved, name: 'Missionary User', email: 'missionary@example.com', password: 'SecurePassword123!') }
    let!(:admin) { create(:user, :admin, name: 'Admin User', email: 'admin@example.com', password: 'SecurePassword123!') }

    it 'supporter can access basic features' do
      sign_in(supporter)
      visit dashboard_path

      expect(page).to have_content('Supporter User')
      # Add more assertions based on your dashboard content
    end

    it 'missionary can access missionary features' do
      sign_in(missionary)
      visit dashboard_path

      expect(page).to have_content('Missionary User')
      # Add more assertions based on your dashboard content
    end

    it 'admin can access admin features' do
      sign_in(admin)
      visit dashboard_path

      expect(page).to have_content('Admin User')
      # Add more assertions based on your dashboard content
    end
  end
end
