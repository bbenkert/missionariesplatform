require 'rails_helper'

RSpec.describe MissionaryProfile, type: :model do
  let(:missionary_profile) { build(:missionary_profile) }

  describe 'validations' do
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:ministry_focus) }
    it { should validate_presence_of(:organization) }
    it { should validate_presence_of(:country) }
    it { should validate_length_of(:bio).is_at_most(2000) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'scopes' do
    let!(:approved_profile) { create(:missionary_profile, user: create(:user, :missionary, :approved)) }
    let!(:pending_profile) { create(:missionary_profile, user: create(:user, :missionary, :pending)) }
    let!(:usa_profile) { create(:missionary_profile, country: 'United States') }
    let!(:uk_profile) { create(:missionary_profile, country: 'United Kingdom') }

    describe '.approved' do
      it 'returns profiles for approved missionaries' do
        expect(MissionaryProfile.approved).to include(approved_profile)
        expect(MissionaryProfile.approved).not_to include(pending_profile)
      end
    end

    describe '.by_country' do
      it 'returns profiles from specified country' do
        expect(MissionaryProfile.by_country('United States')).to include(usa_profile)
        expect(MissionaryProfile.by_country('United States')).not_to include(uk_profile)
      end
    end

    describe '.by_organization' do
      let!(:org1_profile) { create(:missionary_profile, organization: 'Organization A') }
      let!(:org2_profile) { create(:missionary_profile, organization: 'Organization B') }

      it 'returns profiles from specified organization' do
        expect(MissionaryProfile.by_organization('Organization A')).to include(org1_profile)
        expect(MissionaryProfile.by_organization('Organization A')).not_to include(org2_profile)
      end
    end

    describe '.by_ministry_focus' do
      let!(:evangelism_profile) { create(:missionary_profile, ministry_focus: 'Evangelism') }
      let!(:education_profile) { create(:missionary_profile, ministry_focus: 'Education') }

      it 'returns profiles with specified ministry focus' do
        expect(MissionaryProfile.by_ministry_focus('Evangelism')).to include(evangelism_profile)
        expect(MissionaryProfile.by_ministry_focus('Evangelism')).not_to include(education_profile)
      end
    end
  end

  describe 'delegations' do
    let(:user) { create(:user, :missionary, name: 'John Doe') }
    let(:profile) { create(:missionary_profile, user: user) }

    it 'delegates name to user' do
      expect(profile.name).to eq('John Doe')
    end

    it 'delegates email to user' do
      expect(profile.email).to eq(user.email)
    end

    it 'delegates approved? to user' do
      user.update(status: :approved)
      expect(profile.approved?).to be_truthy
    end

    it 'delegates flagged? to user' do
      user.update(status: :flagged)
      expect(profile.flagged?).to be_truthy
    end
  end

  describe 'instance methods' do
    describe '#location_display' do
      it 'returns city and country when both present' do
        profile = build(:missionary_profile, city: 'New York', country: 'United States')
        expect(profile.location_display).to eq('New York, United States')
      end

      it 'returns only country when city is blank' do
        profile = build(:missionary_profile, city: '', country: 'United States')
        expect(profile.location_display).to eq('United States')
      end

      it 'returns only city when country is blank' do
        profile = build(:missionary_profile, city: 'New York', country: '')
        expect(profile.location_display).to eq('New York')
      end
    end

    describe '#ministry_summary' do
      it 'returns ministry focus and organization' do
        profile = build(:missionary_profile, ministry_focus: 'Evangelism', organization: 'World Missions')
        expect(profile.ministry_summary).to eq('Evangelism - World Missions')
      end
    end

    describe '#prayer_requests_list' do
      it 'returns array of prayer requests when present' do
        requests = ["Please pray for our ministry", "Pray for our health", "Pray for our family"]
        profile = build(:missionary_profile, prayer_requests: requests.join("\n"))
        expect(profile.prayer_requests_list).to eq(requests)
      end

      it 'returns empty array when prayer_requests is blank' do
        profile = build(:missionary_profile, prayer_requests: nil)
        expect(profile.prayer_requests_list).to eq([])
      end

      it 'filters out blank lines' do
        requests = "Please pray for our ministry\n\nPray for our health\n"
        profile = build(:missionary_profile, prayer_requests: requests)
        expect(profile.prayer_requests_list).to eq(["Please pray for our ministry", "Pray for our health"])
      end
    end

    describe '#giving_links_list' do
      it 'returns parsed JSON array when giving_links is valid JSON' do
        links = [{ "name" => "PayPal", "url" => "https://paypal.me/example" }]
        profile = build(:missionary_profile, giving_links: links.to_json)
        expect(profile.giving_links_list).to eq(links)
      end

      it 'returns empty array when giving_links is blank' do
        profile = build(:missionary_profile, giving_links: nil)
        expect(profile.giving_links_list).to eq([])
      end

      it 'returns empty array when giving_links is invalid JSON' do
        profile = build(:missionary_profile, giving_links: 'invalid json')
        expect(profile.giving_links_list).to eq([])
      end
    end

    describe '#updates_count' do
      let(:user) { create(:user, :missionary) }
      let(:profile) { create(:missionary_profile, user: user) }

      before do
        create_list(:missionary_update, 3, user: user, status: :published)
        create_list(:missionary_update, 2, user: user, status: :draft)
      end

      it 'returns count of published updates' do
        expect(profile.updates_count).to eq(3)
      end
    end

    describe '#recent_updates' do
      let(:user) { create(:user, :missionary) }
      let(:profile) { create(:missionary_profile, user: user) }

      before do
        @updates = create_list(:missionary_update, 10, user: user, status: :published)
      end

      it 'returns recent published updates' do
        recent = profile.recent_updates
        expect(recent.count).to eq(5) # default limit
        expect(recent).to eq(@updates.last(5).reverse)
      end

      it 'respects custom limit' do
        recent = profile.recent_updates(3)
        expect(recent.count).to eq(3)
      end
    end
  end
end
