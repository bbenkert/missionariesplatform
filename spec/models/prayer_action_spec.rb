require 'rails_helper'

RSpec.describe PrayerAction, type: :model do
  describe 'validations' do
    let(:user) { create(:user) }
    let(:prayer_request) { create(:prayer_request) }
    subject { build(:prayer_action, user: user, prayer_request: prayer_request) }

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:prayer_request) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:prayer_request_id) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:prayer_request) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:prayer_request) { create(:prayer_request) }
    let!(:recent_action) { create(:prayer_action, user: user, prayer_request: prayer_request) }
    let!(:old_action) { create(:prayer_action, user: create(:user), prayer_request: prayer_request, created_at: 2.days.ago) }

    describe '.recent' do
      it 'returns actions ordered by creation date desc' do
        expect(PrayerAction.recent.first).to eq(recent_action)
        expect(PrayerAction.recent.last).to eq(old_action)
      end
    end

    describe '.for_user' do
      let(:other_user) { create(:user) }
      let!(:other_action) { create(:prayer_action, user: other_user, prayer_request: prayer_request) }

      it 'returns actions for specified user' do
        expect(PrayerAction.for_user(user)).to include(recent_action)
        expect(PrayerAction.for_user(user)).not_to include(other_action)
      end
    end

    describe '.for_prayer_request' do
      let(:other_prayer_request) { create(:prayer_request) }
      let!(:other_action) { create(:prayer_action, user: user, prayer_request: other_prayer_request) }

      it 'returns actions for specified prayer request' do
        expect(PrayerAction.for_prayer_request(prayer_request)).to include(recent_action, old_action)
        expect(PrayerAction.for_prayer_request(prayer_request)).not_to include(other_action)
      end
    end
  end

  describe 'class methods' do
    let(:user) { create(:user) }
    let(:prayer_request) { create(:prayer_request) }

    describe '.pray!' do
      context 'when user has not prayed before' do
        it 'creates a new prayer action' do
          expect {
            PrayerAction.pray!(user: user, prayer_request: prayer_request)
          }.to change { PrayerAction.count }.by(1)
        end

        it 'returns the created prayer action' do
          action = PrayerAction.pray!(user: user, prayer_request: prayer_request)
          expect(action).to be_a(PrayerAction)
          expect(action).to be_persisted
          expect(action.user).to eq(user)
          expect(action.prayer_request).to eq(prayer_request)
        end
      end

      context 'when user has already prayed' do
        let!(:existing_action) { create(:prayer_action, user: user, prayer_request: prayer_request) }

        it 'does not create a new prayer action' do
          expect {
            PrayerAction.pray!(user: user, prayer_request: prayer_request)
          }.not_to change { PrayerAction.count }
        end

        it 'returns the existing prayer action' do
          action = PrayerAction.pray!(user: user, prayer_request: prayer_request)
          expect(action).to eq(existing_action)
        end
      end

      context 'with invalid parameters' do
        it 'raises an error when user is nil' do
          expect {
            PrayerAction.pray!(user: nil, prayer_request: prayer_request)
          }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'raises an error when prayer_request is nil' do
          expect {
            PrayerAction.pray!(user: user, prayer_request: nil)
          }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user, name: 'John Doe') }
    let(:prayer_request) { create(:prayer_request, title: 'Healing Prayer') }
    let(:prayer_action) { create(:prayer_action, user: user, prayer_request: prayer_request) }

    describe '#summary' do
      it 'returns a formatted summary of the prayer action' do
        expected = "#{user.name} prayed for \"#{prayer_request.title}\""
        expect(prayer_action.summary).to eq(expected)
      end
    end
  end

  describe 'uniqueness constraint' do
    let(:user) { create(:user) }
    let(:prayer_request) { create(:prayer_request) }

    it 'allows one prayer action per user per prayer request' do
      create(:prayer_action, user: user, prayer_request: prayer_request)
      
      duplicate_action = build(:prayer_action, user: user, prayer_request: prayer_request)
      expect(duplicate_action).not_to be_valid
      expect(duplicate_action.errors[:user_id]).to include('has already been taken')
    end

    it 'allows same user to pray for different requests' do
      other_prayer_request = create(:prayer_request)
      
      create(:prayer_action, user: user, prayer_request: prayer_request)
      other_action = build(:prayer_action, user: user, prayer_request: other_prayer_request)
      
      expect(other_action).to be_valid
    end

    it 'allows different users to pray for same request' do
      other_user = create(:user)
      
      create(:prayer_action, user: user, prayer_request: prayer_request)
      other_action = build(:prayer_action, user: other_user, prayer_request: prayer_request)
      
      expect(other_action).to be_valid
    end
  end

  describe 'database constraints' do
    let(:user) { create(:user) }
    let(:prayer_request) { create(:prayer_request) }

    it 'enforces uniqueness at database level' do
      create(:prayer_action, user: user, prayer_request: prayer_request)
      
      expect {
        # Bypass Rails validations to test database constraint
        connection = ActiveRecord::Base.connection
        timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
        connection.execute(
          "INSERT INTO prayer_actions (prayer_request_id, user_id, created_at, updated_at) VALUES (#{prayer_request.id}, #{user.id}, '#{timestamp}', '#{timestamp}')"
        )
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
