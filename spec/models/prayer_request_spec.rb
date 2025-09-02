require 'rails_helper'

RSpec.describe PrayerRequest, type: :model do
  describe 'validations' do
    subject { build(:prayer_request) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:title).is_at_most(255) }
    it { should validate_length_of(:body).is_at_most(5000) }
  end

  describe 'associations' do
    it { should belong_to(:missionary_profile) }
    it { should have_many(:prayer_actions).dependent(:destroy) }
    it { should have_many(:praying_users).through(:prayer_actions) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(open: 0, answered: 1, closed: 2).with_prefix(:status) }
    it { should define_enum_for(:urgency).with_values(low: 0, medium: 1, high: 2).with_prefix(:urgency) }
  end

  

  describe 'scopes' do
    let!(:published_request) { create(:prayer_request, status: :open) }
    let!(:draft_request) { create(:prayer_request, status: :closed) }
    let!(:urgent_request) { create(:prayer_request, urgency: :high, status: :open) }
    let!(:old_request) { create(:prayer_request, status: :open, created_at: 2.days.ago) }

    describe '.published' do
      it 'returns only published prayer requests' do
        expect(PrayerRequest.published).to include(published_request, urgent_request, old_request)
        expect(PrayerRequest.published).not_to include(draft_request)
      end
    end

    describe '.urgent' do
      it 'returns only urgent prayer requests' do
        expect(PrayerRequest.urgent).to include(urgent_request)
        expect(PrayerRequest.urgent).not_to include(published_request)
      end
    end

    describe '.recent' do
      it 'returns requests ordered by creation date desc' do
        expect(PrayerRequest.recent.first).to eq(urgent_request)
        expect(PrayerRequest.recent.last).to eq(old_request)
      end
    end

    describe '.with_tag' do
      let!(:healing_request) { create(:prayer_request, tags: ['healing', 'health']) }
      let!(:travel_request) { create(:prayer_request, tags: ['travel', 'safety']) }

      it 'returns requests containing the specified tag' do
        expect(PrayerRequest.by_tags(['healing'])).to include(healing_request)
        expect(PrayerRequest.by_tags(['healing'])).not_to include(travel_request)
      end
    end
  end

  describe 'instance methods' do
    let(:prayer_request) { create(:prayer_request, tags: ['healing', 'family']) }

    describe '#prayer_count' do
      it 'returns the number of prayer actions' do
        user1 = create(:user)
        user2 = create(:user)
        
        create(:prayer_action, user: user1, prayer_request: prayer_request)
        create(:prayer_action, user: user2, prayer_request: prayer_request)
        
        expect(prayer_request.prayer_count).to eq(2)
      end
    end

    describe '#prayed_by?' do
      let(:user) { create(:user) }

      it 'returns true if user has prayed for this request' do
        create(:prayer_action, user: user, prayer_request: prayer_request)
        expect(prayer_request.prayed_by?(user)).to be true
      end

      it 'returns false if user has not prayed for this request' do
        expect(prayer_request.prayed_by?(user)).to be false
      end

      it 'returns false if user is nil' do
        expect(prayer_request.prayed_by?(nil)).to be false
      end
    end

    describe '#tag_list' do
      it 'returns tags as a comma-separated string' do
        expect(prayer_request.tag_list).to eq('healing, family')
      end

      it 'returns empty string if no tags' do
        prayer_request.update!(tags: [])
        expect(prayer_request.tag_list).to eq('')
      end
    end

    describe '#urgency_color' do
      it 'returns correct color for each urgency level' do
        expect(build(:prayer_request, urgency: :low).urgency_color).to eq('green')
        expect(build(:prayer_request, urgency: :medium).urgency_color).to eq('yellow')
        expect(build(:prayer_request, urgency: :high).urgency_color).to eq('orange')
      end
    end
  end

  describe 'search functionality' do
    let!(:healing_request) { create(:prayer_request, title: 'Healing Prayer', body: 'Please pray for healing and recovery') }
    let!(:travel_request) { create(:prayer_request, title: 'Safe Travel', body: 'Traveling to remote mission field') }

    describe '.search' do
      it 'finds requests by title' do
        results = PrayerRequest.search('healing')
        expect(results).to include(healing_request)
        expect(results).not_to include(travel_request)
      end

      it 'finds requests by body content' do
        results = PrayerRequest.search('mission')
        expect(results).to include(travel_request)
        expect(results).not_to include(healing_request)
      end

      it 'returns empty results for non-matching search' do
        results = PrayerRequest.search('nonexistent')
        expect(results).to be_empty
      end
    end
  end

    describe 'JSONB tags' do
    let(:prayer_request) { create(:prayer_request) }

    it 'can store and query complex tag structures' do
      tags = ['healing', 'family', 'urgent-care', 'missionary-health']
      prayer_request.update!(tags: tags)
      prayer_request.reload
      
      expect(prayer_request.tags).to eq(tags)
      expect(PrayerRequest.by_tags(['healing']).count).to eq(1)
      expect(PrayerRequest.by_tags(['family']).count).to eq(1)
    end

    it 'handles empty tags array' do
      prayer_request.update!(tags: [])
      expect(prayer_request.tags).to eq([])
      expect(prayer_request.tag_list).to eq('')
    end
  end
end
