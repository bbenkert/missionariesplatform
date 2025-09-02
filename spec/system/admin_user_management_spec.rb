require 'rails_helper'

RSpec.describe 'Admin User Management', type: :system, js: true do
  let(:admin) { create(:user, :admin) }
  let!(:supporters) { create_list(:user, :supporter, 3, status: 'approved') }
  let!(:missionaries) { create_list(:user, :missionary, 2, status: 'pending') }
  let!(:suspended_user) { create(:user, :suspended) }

  before do
    sign_in admin
  end

  describe 'Users index page' do
    before { visit admin_users_path }

    it 'displays user statistics' do
      within('.stats-dashboard') do
        expect(page).to have_content('Total Users')
        expect(page).to have_content('Supporters')
        expect(page).to have_content('Missionaries')
        expect(page).to have_content('Pending Users')
      end
    end

    it 'displays users table' do
      expect(page).to have_css('table tbody tr', count: 7) # 3 supporters + 2 missionaries + 1 suspended + 1 admin
      
      supporters.each do |supporter|
        expect(page).to have_content(supporter.name)
        expect(page).to have_content(supporter.email)
      end
    end

    it 'shows role and status badges' do
      expect(page).to have_css('.role-badge', minimum: 1)
      expect(page).to have_css('.status-badge', minimum: 1)
    end

    describe 'filtering' do
      it 'filters users by role' do
        select 'Supporters', from: 'role'
        click_button 'Apply Filters'
        
        expect(page).to have_css('table tbody tr', count: 3)
        supporters.each do |supporter|
          expect(page).to have_content(supporter.name)
        end
      end

      it 'filters users by status' do
        select 'Pending', from: 'status'
        click_button 'Apply Filters'
        
        expect(page).to have_css('table tbody tr', count: 2)
        missionaries.each do |missionary|
          expect(page).to have_content(missionary.name)
        end
      end
    end

    describe 'search functionality' do
      it 'searches users by name' do
        fill_in 'search', with: supporters.first.name
        click_button 'Apply Filters'
        
        expect(page).to have_content(supporters.first.name)
        expect(page).not_to have_content(supporters.last.name)
      end

      it 'searches users by email' do
        fill_in 'search', with: supporters.first.email
        click_button 'Apply Filters'
        
        expect(page).to have_content(supporters.first.name)
        expect(page).not_to have_content(supporters.last.name)
      end
    end

    describe 'bulk actions' do
      it 'selects all users when clicking select all checkbox' do
        check 'select-all-users'
        
        # All individual checkboxes should be checked
        all('input[name="user_ids[]"]').each do |checkbox|
          expect(checkbox).to be_checked
        end
      end

      it 'enables bulk action button when users are selected' do
        # Initially bulk action should be disabled or not visible
        expect(page).to have_css('#bulk-action-form', visible: false)
        
        # Select first user
        first('input[name="user_ids[]"]').check
        
        # Bulk action form should become visible
        expect(page).to have_css('#bulk-action-form', visible: true)
      end

      it 'performs bulk suspend action', :js do
        # Select some users
        missionaries.each_with_index do |missionary, index|
          find("input[value='#{missionary.id}']").check
        end

        select 'Suspend Selected Users', from: 'action_type'
        
        accept_confirm do
          click_button 'Apply Action'
        end

        expect(page).to have_content('Bulk action completed successfully')
        
        missionaries.each do |missionary|
          missionary.reload
          expect(missionary.status).to eq('suspended')
        end
      end
    end
  end

  describe 'User show page' do
    let(:user) { supporters.first }
    
    before { visit admin_user_path(user) }

    it 'displays user profile information' do
      expect(page).to have_content(user.name)
      expect(page).to have_content(user.email)
      expect(page).to have_content(user.role.humanize)
      expect(page).to have_content(user.status.humanize)
    end

    it 'shows activity statistics' do
      within('.activity-stats') do
        expect(page).to have_content('Activity Statistics')
      end
    end

    it 'displays recent activity timeline' do
      expect(page).to have_css('.activity-timeline')
    end

    it 'shows email logs section' do
      expect(page).to have_content('Email Delivery Logs')
    end

    it 'shows notifications history' do
      expect(page).to have_content('Notification History')
    end

    it 'has action buttons' do
      expect(page).to have_link('Edit User')
      if user.status != 'suspended'
        expect(page).to have_button('Suspend User')
      end
    end
  end

  describe 'User edit page' do
    let(:user) { supporters.first }
    
    before { visit edit_admin_user_path(user) }

    it 'displays edit form with user information' do
      expect(page).to have_field('user_name', with: user.name)
      expect(page).to have_field('user_email', with: user.email)
      expect(page).to have_select('user_role', selected: user.role.humanize)
      expect(page).to have_select('user_status', selected: user.status.humanize)
    end

    it 'updates user information successfully' do
      fill_in 'user_name', with: 'Updated Name'
      fill_in 'user_email', with: 'updated@example.com'
      select 'Supporter', from: 'user_role'
      select 'Active', from: 'user_status'
      
      click_button 'Save Changes'
      
      expect(page).to have_content('User updated successfully')
      expect(page).to have_content('Updated Name')
      expect(page).to have_content('updated@example.com')
    end

    it 'displays notification preferences section' do
      expect(page).to have_content('Notification Preferences')
      expect(page).to have_field('user_weekly_digest_enabled')
      expect(page).to have_field('user_prayer_request_notifications')
    end

    it 'displays location information section' do
      expect(page).to have_content('Location Information')
      expect(page).to have_field('user_city')
      expect(page).to have_field('user_country')
      expect(page).to have_select('user_time_zone')
    end

    context 'when editing missionary user' do
      let(:missionary) { missionaries.first }
      
      before { visit edit_admin_user_path(missionary) }

      it 'shows missionary status section' do
        expect(page).to have_content('Missionary Status')
      end

      it 'shows approve missionary button if not approved' do
        if missionary.status == 'pending'
          expect(page).to have_link('Approve Missionary')
        end
      end
    end
  end

  describe 'Individual user actions' do
    context 'approving missionary' do
      let(:missionary) { missionaries.first }
      
      it 'approves missionary from user show page' do
        visit admin_user_path(missionary)
        
        click_link 'Approve Missionary'
        
        expect(page).to have_content('Missionary approved successfully')
        
        missionary.reload
        expect(missionary.status).to eq('approved')
        expect(missionary.missionary_profile).to be_present
      end
    end

    context 'suspending user' do
      let(:user) { supporters.first }
      
      it 'suspends user from user show page' do
        visit admin_user_path(user)
        
        accept_confirm do
          click_button 'Suspend User'
        end
        
        expect(page).to have_content('User suspended successfully')
        
        user.reload
        expect(user.status).to eq('suspended')
      end
    end

    context 'activating suspended user' do
      it 'activates user from user show page' do
        visit admin_user_path(suspended_user)
        
        accept_confirm do
          click_button 'Activate User'
        end
        
        expect(page).to have_content('User activated successfully')
        
        suspended_user.reload
        expect(suspended_user.status).to eq('approved')
      end
    end
  end

  describe 'navigation and UI' do
    before { visit admin_users_path }

    it 'has proper navigation breadcrumbs' do
      expect(page).to have_content('Admin')
      expect(page).to have_content('Users')
    end

    it 'has responsive design elements' do
      expect(page).to have_css('.bg-gradient-to-br')
      expect(page).to have_css('.backdrop-blur-sm')
    end

    it 'displays proper icons and styling' do
      expect(page).to have_css('.fas')
      expect(page).to have_css('.rounded-xl')
    end
  end
end
