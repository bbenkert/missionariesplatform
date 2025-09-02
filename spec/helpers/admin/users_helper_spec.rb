require 'rails_helper'

RSpec.describe Admin::UsersHelper, type: :helper do
  let(:user) { create(:user, :supporter, status: 'approved', email_verified: true) }
  let(:admin) { create(:user, :admin) }
  let(:missionary) { create(:user, :missionary, status: 'pending') }

  describe '#user_status_badge' do
    it 'returns correct badge for active user' do
      user.update(status: 'approved')
      badge = helper.user_status_badge(user)
      expect(badge).to include('Active')
      expect(badge).to include('bg-green-100 text-green-800')
    end

    it 'returns correct badge for pending user' do
      user.update(status: 'pending')
      badge = helper.user_status_badge(user)
      expect(badge).to include('Pending')
      expect(badge).to include('bg-yellow-100 text-yellow-800')
    end

    it 'returns correct badge for suspended user' do
      user.update(status: 'suspended')
      badge = helper.user_status_badge(user)
      expect(badge).to include('Suspended')
      expect(badge).to include('bg-red-100 text-red-800')
    end

    it 'returns correct badge for inactive user' do
      user.update(status: 'inactive')
      badge = helper.user_status_badge(user)
      expect(badge).to include('Inactive')
      expect(badge).to include('bg-gray-100 text-gray-800')
    end
  end

  describe '#user_role_badge' do
    it 'returns correct badge for admin' do
      badge = helper.user_role_badge(admin)
      expect(badge).to include('Admin')
      expect(badge).to include('bg-purple-100 text-purple-800')
    end

    it 'returns correct badge for missionary' do
      badge = helper.user_role_badge(missionary)
      expect(badge).to include('Missionary')
      expect(badge).to include('bg-blue-100 text-blue-800')
    end

    it 'returns correct badge for supporter' do
      badge = helper.user_role_badge(user)
      expect(badge).to include('Supporter')
      expect(badge).to include('bg-green-100 text-green-800')
    end

    it 'returns correct badge for organization admin' do
      org_admin = create(:user, :organization_admin)
      badge = helper.user_role_badge(org_admin)
      expect(badge).to include('Org Admin')
      expect(badge).to include('bg-indigo-100 text-indigo-800')
    end
  end

  describe '#user_email_status_badge' do
    context 'when email is verified' do
      it 'returns verified badge' do
        user.update(email_verified: true)
        badge = helper.user_email_status_badge(user)
        expect(badge).to include('Verified')
        expect(badge).to include('fas fa-check-circle text-green-500')
      end
    end

    context 'when email is not verified' do
      it 'returns unverified badge' do
        user.update(email_verified: false)
        badge = helper.user_email_status_badge(user)
        expect(badge).to include('Unverified')
        expect(badge).to include('fas fa-exclamation-triangle text-yellow-500')
      end
    end
  end

  describe '#last_sign_in_text' do
    context 'when user has signed in before' do
      it 'returns time ago text' do
        user.update(last_sign_in_at: 2.days.ago)
        text = helper.last_sign_in_text(user)
        expect(text).to include('ago')
      end
    end

    context 'when user has never signed in' do
      it 'returns Never' do
        user.update(last_sign_in_at: nil)
        text = helper.last_sign_in_text(user)
        expect(text).to eq('Never')
      end
    end
  end

  describe '#user_activity_status' do
    context 'when user signed in recently (within 7 days)' do
      it 'returns active status' do
        user.update(last_sign_in_at: 3.days.ago)
        status = helper.user_activity_status(user)
        expect(status[:text]).to eq('Active')
        expect(status[:class]).to eq('text-green-600')
      end
    end

    context 'when user signed in within 30 days' do
      it 'returns recent status' do
        user.update(last_sign_in_at: 15.days.ago)
        status = helper.user_activity_status(user)
        expect(status[:text]).to eq('Recent')
        expect(status[:class]).to eq('text-yellow-600')
      end
    end

    context 'when user signed in more than 30 days ago' do
      it 'returns inactive status' do
        user.update(last_sign_in_at: 45.days.ago)
        status = helper.user_activity_status(user)
        expect(status[:text]).to eq('Inactive')
        expect(status[:class]).to eq('text-red-600')
      end
    end

    context 'when user has never signed in' do
      it 'returns never active status' do
        user.update(last_sign_in_at: nil)
        status = helper.user_activity_status(user)
        expect(status[:text]).to eq('Never Active')
        expect(status[:class]).to eq('text-gray-600')
      end
    end
  end

  describe '#format_user_activity_item' do
    it 'formats sign in activity' do
      item = { type: 'sign_in', ip: '192.168.1.1' }
      formatted = helper.format_user_activity_item(item)
      expect(formatted[:icon]).to eq('fas fa-sign-in-alt')
      expect(formatted[:color]).to eq('green')
      expect(formatted[:title]).to eq('Signed In')
      expect(formatted[:description]).to include('192.168.1.1')
    end

    it 'formats profile update activity' do
      item = { type: 'profile_update' }
      formatted = helper.format_user_activity_item(item)
      expect(formatted[:icon]).to eq('fas fa-user-edit')
      expect(formatted[:color]).to eq('blue')
      expect(formatted[:title]).to eq('Profile Updated')
    end

    it 'formats prayer request activity' do
      item = { type: 'prayer_request' }
      formatted = helper.format_user_activity_item(item)
      expect(formatted[:icon]).to eq('fas fa-pray')
      expect(formatted[:color]).to eq('purple')
      expect(formatted[:title]).to eq('Prayer Request Created')
    end

    it 'formats message activity' do
      item = { type: 'message_sent' }
      formatted = helper.format_user_activity_item(item)
      expect(formatted[:icon]).to eq('fas fa-paper-plane')
      expect(formatted[:color]).to eq('indigo')
      expect(formatted[:title]).to eq('Message Sent')
    end

    it 'formats unknown activity' do
      item = { type: 'unknown', description: 'Custom activity' }
      formatted = helper.format_user_activity_item(item)
      expect(formatted[:icon]).to eq('fas fa-info-circle')
      expect(formatted[:color]).to eq('gray')
      expect(formatted[:title]).to eq('Activity')
      expect(formatted[:description]).to eq('Custom activity')
    end
  end

  describe '#filter_options' do
    it 'returns role filter options' do
      options = helper.filter_options
      expect(options[:roles]).to include(['All Roles', ''])
      expect(options[:roles]).to include(['Supporters', 'supporter'])
      expect(options[:roles]).to include(['Missionaries', 'missionary'])
      expect(options[:roles]).to include(['Admins', 'admin'])
    end

    it 'returns status filter options' do
      options = helper.filter_options
      expect(options[:statuses]).to include(['All Statuses', ''])
      expect(options[:statuses]).to include(['Active', 'active'])
      expect(options[:statuses]).to include(['Pending', 'pending'])
      expect(options[:statuses]).to include(['Suspended', 'suspended'])
    end

    it 'returns email verification filter options' do
      options = helper.filter_options
      expect(options[:email_verified]).to include(['All Users', ''])
      expect(options[:email_verified]).to include(['Verified Email', 'true'])
      expect(options[:email_verified]).to include(['Unverified Email', 'false'])
    end
  end

  describe '#bulk_action_options' do
    it 'returns bulk action options' do
      options = helper.bulk_action_options
      expect(options).to include(['Select Action', ''])
      expect(options).to include(['Approve Selected Missionaries', 'approve_missionaries'])
      expect(options).to include(['Suspend Selected Users', 'suspend'])
      expect(options).to include(['Activate Selected Users', 'activate'])
      expect(options).to include(['Delete Selected Users', 'delete'])
    end
  end
end
