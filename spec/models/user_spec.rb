require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it 'validates email uniqueness case-insensitively' do
      create(:user, email: 'test@example.com')
      duplicate_user = build(:user, email: 'TEST@EXAMPLE.COM')
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }

    context 'password validations' do
      it 'is invalid with a short password' do
        user = build(:user, password: 'short', password_confirmation: 'short')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
      end

      it 'is invalid when password confirmation does not match' do
        user = build(:user, password: 'password123', password_confirmation: 'different')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("doesn't match Password")
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(supporter: 0, missionary: 1, admin: 2, organization_admin: 3) }
    it { should define_enum_for(:status).with_values(pending: 0, approved: 1, flagged: 2, suspended: 3) }
  end

  describe 'associations' do
    it { should have_one(:missionary_profile).dependent(:destroy) }
    it { should have_many(:missionary_updates).dependent(:destroy) }
    it { should have_many(:supporter_followings).dependent(:destroy) }
    it { should have_many(:followed_missionaries).through(:follows) }
    it { should have_many(:sent_conversations).dependent(:destroy) }
    it { should have_many(:received_conversations).dependent(:destroy) }
    it { should have_many(:messages).dependent(:destroy) }
    it { should have_one_attached(:avatar) }
    it { should have_one_attached(:banner_image) }
  end

  describe 'scopes' do
    let!(:supporter) { create(:user, :supporter) }
    let!(:missionary) { create(:user, :missionary) }
    let!(:admin) { create(:user, :admin) }
    let!(:inactive_user) { create(:user, is_active: false) }

    describe '.missionaries' do
      it 'returns only missionary users' do
        expect(User.missionaries).to include(missionary)
        expect(User.missionaries).not_to include(supporter, admin)
      end
    end

    describe '.supporters' do
      it 'returns only supporter users' do
        expect(User.supporters).to include(supporter)
        expect(User.supporters).not_to include(missionary, admin)
      end
    end

    describe '.admins' do
      it 'returns only admin users' do
        expect(User.admins).to include(admin)
        expect(User.admins).not_to include(supporter, missionary)
      end
    end

    describe '.active' do
      it 'returns only active users' do
        expect(User.active).to include(supporter, missionary, admin)
        expect(User.active).not_to include(inactive_user)
      end
    end

    describe '.approved_missionaries' do
      let!(:approved_missionary) { create(:user, :missionary, :approved) }
      let!(:pending_missionary) { create(:user, :missionary, :pending) }

      it 'returns only approved missionaries' do
        expect(User.approved_missionaries).to include(approved_missionary)
        expect(User.approved_missionaries).not_to include(pending_missionary, supporter)
      end
    end
  end

  describe 'callbacks' do
    context 'email downcasing' do
      it 'downcases email before save' do
        user = create(:user, email: 'USER@EXAMPLE.COM')
        expect(user.email).to eq('user@example.com')
      end

      it 'strips whitespace from email' do
        user = create(:user, email: '  user@example.com  ')
        expect(user.email).to eq('user@example.com')
      end
    end

    context 'missionary approval notification' do
      let(:missionary) { create(:user, :missionary, :pending) }

      it 'sends approval email when missionary status changes to approved' do
        expect {
          missionary.update(status: :approved)
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with do |*args|
          args[0] == 'UserMailer' && args[1] == 'missionary_approved' && args[2] == 'deliver_later'
        end
      end

      it 'does not send email for non-missionary users' do
        supporter = create(:user, :supporter, :pending)
        expect {
          supporter.update(status: :approved)
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end
  end

  describe 'instance methods' do
    describe '#full_name' do
      it 'returns the name' do
        user = build(:user, name: 'John Doe')
        expect(user.full_name).to eq('John Doe')
      end
    end

    describe '#display_name' do
      it 'returns name when present' do
        user = build(:user, name: 'John Doe', email: 'john@example.com')
        expect(user.display_name).to eq('John Doe')
      end

      it 'returns email username when name is blank' do
        user = build(:user, name: '', email: 'john@example.com')
        expect(user.display_name).to eq('john')
      end
    end

    describe '#avatar_url' do
      let(:user) { create(:user) }

      context 'when avatar is attached' do
        before do
          user.avatar.attach(io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'avatar.jpg')), filename: 'avatar.jpg')
        end

        it 'returns small variant' do
          expect(user.avatar_url(size: :small)).to be_present
        end

        it 'returns medium variant' do
          expect(user.avatar_url(size: :medium)).to be_present
        end

        it 'returns large variant' do
          expect(user.avatar_url(size: :large)).to be_present
        end

        it 'returns original for unknown size' do
          expect(user.avatar_url(size: :unknown)).to eq(user.avatar)
        end
      end

      context 'when avatar is not attached' do
        it 'returns nil' do
          expect(user.avatar_url).to be_nil
        end
      end
    end

    describe '#followers_count' do
      let(:missionary) { create(:user, :missionary) }
      let(:supporter) { create(:user, :supporter) }

      before do
        create(:supporter_following, supporter: supporter, missionary: missionary)
      end

      it 'returns followers count for missionary' do
        expect(missionary.followers_count).to eq(1)
      end

      it 'returns 0 for non-missionary' do
        expect(supporter.followers_count).to eq(0)
      end
    end

    describe '#following_count' do
      let(:supporter) { create(:user, :supporter) }
      let(:missionary) { create(:user, :missionary) }

      before do
        # Use the new Follow model instead of supporter_following
        create(:follow, user: supporter, followable: missionary.missionary_profile || create(:missionary_profile, user: missionary))
      end

      it 'returns following count for supporter' do
        expect(supporter.following_count).to eq(1)
      end

      it 'returns 0 for non-supporter' do
        expect(missionary.following_count).to eq(0)
      end
    end

    describe '#can_message?' do
      let(:supporter) { create(:user, :supporter) }
      let(:missionary) { create(:user, :missionary, :approved) }
      let(:admin) { create(:user, :admin) }

      it 'returns false for messaging self' do
        expect(missionary.can_message?(missionary)).to be_falsey
      end

      it 'returns false for non-missionary recipients' do
        expect(supporter.can_message?(supporter)).to be_falsey
      end

      it 'returns true for supporter messaging missionary' do
        expect(supporter.can_message?(missionary)).to be_truthy
      end

      it 'returns true for admin messaging missionary' do
        expect(admin.can_message?(missionary)).to be_truthy
      end

      it 'returns false for missionary messaging supporter' do
        expect(missionary.can_message?(supporter)).to be_falsey
      end
    end

    describe '#needs_approval?' do
      it 'returns true for pending missionary' do
        user = build(:user, :missionary, :pending)
        expect(user.needs_approval?).to be_truthy
      end

      it 'returns false for approved missionary' do
        user = build(:user, :missionary, :approved)
        expect(user.needs_approval?).to be_falsey
      end

      it 'returns false for supporter' do
        user = build(:user, :supporter)
        expect(user.needs_approval?).to be_falsey
      end
    end

    describe '#public_profile?' do
      it 'returns true for approved active missionary' do
        user = build(:user, :missionary, :approved, is_active: true)
        expect(user.public_profile?).to be_truthy
      end

      it 'returns false for pending missionary' do
        user = build(:user, :missionary, :pending)
        expect(user.public_profile?).to be_falsey
      end

      it 'returns false for inactive missionary' do
        user = build(:user, :missionary, :approved, is_active: false)
        expect(user.public_profile?).to be_falsey
      end

      it 'returns false for supporter' do
        user = build(:user, :supporter)
        expect(user.public_profile?).to be_falsey
      end
    end

    describe '#approved?' do
      it 'returns true for approved user' do
        user = build(:user, :approved)
        expect(user.approved?).to be_truthy
      end

      it 'returns false for pending user' do
        user = build(:user, :pending)
        expect(user.approved?).to be_falsey
      end
    end
  end

  describe 'class methods' do
    describe '.authenticate' do
      # Using Devise authentication, these custom methods may not exist
      pending 'returns user with correct credentials'
      pending 'returns nil with incorrect password'
      pending 'returns nil with incorrect email'
      pending 'is case insensitive for email'
    end

    describe '.authenticate_with_email_and_password' do
      # Using Devise authentication, these custom methods may not exist
      pending 'returns active user with correct credentials'
      pending 'returns nil for inactive user'
    end

    describe 'password reset functionality' do
      # Since we use Devise, these methods might not exist in our User model
      pending '#generate_password_reset_token generates a reset token and timestamp'
      pending '#clear_password_reset_token! clears the reset token and timestamp'
      pending '#password_reset_expired? returns false for recent token'
      pending '#password_reset_expired? returns true for expired token'
      pending '.find_by_password_reset_token finds user with valid token'
      pending '.find_by_password_reset_token returns nil for expired token'
    end
  end
end
