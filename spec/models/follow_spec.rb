require 'rails_helper'

RSpec.describe Follow, type: :model do
  describe 'validations' do
    let(:user) { create(:user) }
    let(:missionary_profile) { create(:missionary_profile) }
    subject { build(:follow, user: user, followable: missionary_profile) }

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:followable) }
    
    it 'validates uniqueness of user_id scoped to followable' do
      create(:follow, user: user, followable: missionary_profile)
      duplicate_follow = build(:follow, user: user, followable: missionary_profile)
      
      expect(duplicate_follow).not_to be_valid
      expect(duplicate_follow.errors[:user_id]).to include('is already following this')
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:followable) }
  end

  describe 'scopes' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:missionary_profile) { create(:missionary_profile) }
    let(:organization) { create(:organization) }
    
    let!(:missionary_follow) { create(:follow, user: user1, followable: missionary_profile) }
    let!(:org_follow) { create(:follow, user: user2, followable: organization) }
    let!(:notify_follow) { create(:follow, user: user1, followable: organization, notifications_enabled: true) }
    let!(:no_notify_follow) { create(:follow, user: user2, followable: missionary_profile, notifications_enabled: false) }

    describe '.with_notifications' do
      it 'returns follows with notifications enabled' do
        expect(Follow.with_notifications).to include(notify_follow)
        expect(Follow.with_notifications).not_to include(no_notify_follow)
      end
    end

    describe '.recent' do
      let!(:old_follow) { create(:follow, user: user3, followable: organization, created_at: 2.days.ago) }
      
      it 'returns follows ordered by creation date desc' do
        expect(Follow.recent.first).to eq(no_notify_follow) # Most recent
        expect(Follow.recent.last).to eq(old_follow) # Oldest
      end
    end

    describe '.for_missionaries' do
      it 'returns follows for missionary profiles only' do
        expect(Follow.for_missionaries).to include(missionary_follow, no_notify_follow)
        expect(Follow.for_missionaries).not_to include(org_follow, notify_follow)
      end
    end

    describe '.for_organizations' do
      it 'returns follows for organizations only' do
        expect(Follow.for_organizations).to include(org_follow, notify_follow)
        expect(Follow.for_organizations).not_to include(missionary_follow, no_notify_follow)
      end
    end
  end

  describe 'class methods' do
    let(:user) { create(:user) }
    let(:missionary_profile) { create(:missionary_profile) }

    describe '.follow!' do
      context 'when not already following' do
        it 'creates a new follow record' do
          expect {
            Follow.follow!(user: user, followable: missionary_profile)
          }.to change { Follow.count }.by(1)
        end

        it 'returns the created follow' do
          follow = Follow.follow!(user: user, followable: missionary_profile)
          expect(follow).to be_a(Follow)
          expect(follow).to be_persisted
          expect(follow.user).to eq(user)
          expect(follow.followable).to eq(missionary_profile)
        end
      end

      context 'when already following' do
        let!(:existing_follow) { create(:follow, user: user, followable: missionary_profile) }

        it 'does not create a new follow' do
          expect {
            Follow.follow!(user: user, followable: missionary_profile)
          }.not_to change { Follow.count }
        end

        it 'returns the existing follow' do
          follow = Follow.follow!(user: user, followable: missionary_profile)
          expect(follow).to eq(existing_follow)
        end
      end
    end

    describe '.unfollow!' do
      let!(:follow1) { create(:follow, user: user, followable: missionary_profile) }
      let!(:follow2) { create(:follow, user: create(:user), followable: missionary_profile) }

      it 'destroys all follows for user and followable' do
        expect {
          Follow.unfollow!(user: user, followable: missionary_profile)
        }.to change { Follow.count }.by(-1)
        
        expect(Follow.exists?(follow1.id)).to be false
        expect(Follow.exists?(follow2.id)).to be true
      end

      it 'returns destroyed follows count' do
        result = Follow.unfollow!(user: user, followable: missionary_profile)
        expect(result).to eq(1)
      end

      context 'when not following' do
        let(:other_user) { create(:user) }

        it 'does not raise error' do
          expect {
            Follow.unfollow!(user: other_user, followable: missionary_profile)
          }.not_to raise_error
        end

        it 'returns zero' do
          result = Follow.unfollow!(user: other_user, followable: missionary_profile)
          expect(result).to eq(0)
        end
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:missionary_profile) { create(:missionary_profile) }
    let(:organization) { create(:organization) }

    describe '#missionary_profile?' do
      it 'returns true for missionary profile follows' do
        follow = create(:follow, user: user, followable: missionary_profile)
        expect(follow.missionary_profile?).to be true
      end

      it 'returns false for organization follows' do
        follow = create(:follow, user: user, followable: organization)
        expect(follow.missionary_profile?).to be false
      end
    end

    describe '#organization?' do
      it 'returns true for organization follows' do
        follow = create(:follow, user: user, followable: organization)
        expect(follow.organization?).to be true
      end

      it 'returns false for missionary profile follows' do
        follow = create(:follow, user: user, followable: missionary_profile)
        expect(follow.organization?).to be false
      end
    end
  end

  describe 'polymorphic associations' do
    let(:user) { create(:user) }

    it 'works with MissionaryProfile' do
      missionary_profile = create(:missionary_profile)
      follow = create(:follow, user: user, followable: missionary_profile)
      
      expect(follow.followable).to eq(missionary_profile)
      expect(follow.followable_type).to eq('MissionaryProfile')
    end

    it 'works with Organization' do
      organization = create(:organization)
      follow = create(:follow, user: user, followable: organization)
      
      expect(follow.followable).to eq(organization)
      expect(follow.followable_type).to eq('Organization')
    end
  end

  describe 'defaults' do
    let(:user) { create(:user) }
    let(:missionary_profile) { create(:missionary_profile) }

    it 'sets notifications_enabled to true by default' do
      follow = create(:follow, user: user, followable: missionary_profile)
      expect(follow.notifications_enabled).to be true
    end
  end

  describe 'uniqueness constraint enforcement' do
    let(:user) { create(:user) }
    let(:missionary_profile) { create(:missionary_profile) }

    it 'prevents duplicate follows at database level' do
      create(:follow, user: user, followable: missionary_profile)
      
      expect {
        Follow.create!(user: user, followable: missionary_profile)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
