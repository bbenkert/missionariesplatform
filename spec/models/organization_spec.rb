require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'validations' do
    subject { build(:organization) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it 'validates presence of slug' do
      org = Organization.new(name: 'Test Org', slug: '')
      org.valid?
      expect(org.errors[:slug]).to include("can't be blank")
    end
    it { should validate_uniqueness_of(:slug).case_insensitive }
    it { should allow_value('test@example.com').for(:contact_email) }
    it { should allow_value('').for(:contact_email) }
    it { should allow_value(nil).for(:contact_email) }
    it { should_not allow_value('invalid-email').for(:contact_email) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe 'associations' do
    it { should have_many(:users).dependent(:nullify) }
    it { should have_many(:follows).dependent(:destroy) }
    it { should have_many(:followers).through(:follows) }
    
    it 'has missionaries through users with role filtering' do
      org = create(:organization)
      missionary_user = create(:user, :missionary, organization: org)
      supporter_user = create(:user, :supporter, organization: org)
      
      expect(org.missionaries).to include(missionary_user)
      expect(org.missionaries).not_to include(supporter_user)
    end
  end

  describe 'callbacks' do
    it 'generates slug before validation' do
      org = build(:organization, name: 'Test Organization', slug: nil)
      expect { org.valid? }.to change { org.slug }.from(nil).to('test-organization')
    end

    it 'does not overwrite existing slug' do
      org = build(:organization, name: 'Test Organization', slug: 'custom-slug')
      org.valid?
      expect(org.slug).to eq('custom-slug')
    end
  end

  describe 'scopes' do
    let!(:org1) { create(:organization) }
    let!(:org2) { create(:organization) }

    describe '.active' do
      it 'returns all organizations (all are considered active)' do
        expect(Organization.active).to include(org1, org2)
      end
    end

    describe '.by_name' do
      it 'returns organizations ordered by name' do
        org_z = create(:organization, name: 'Z Organization')
        org_a = create(:organization, name: 'A Organization')
        
        expect(Organization.by_name.first).to eq(org_a)
        expect(Organization.by_name.last).to eq(org_z)
      end
    end
  end

  describe 'instance methods' do
    let(:organization) { create(:organization, settings: { allow_public_profiles: true, auto_approve_missionaries: false }) }

    describe '#followers_count' do
      it 'returns the number of followers' do
        user1 = create(:user)
        user2 = create(:user)
        
        create(:follow, user: user1, followable: organization)
        create(:follow, user: user2, followable: organization)
        
        expect(organization.followers_count).to eq(2)
      end
    end

    describe '#missionaries_count' do
      it 'returns the number of missionaries in the organization' do
        create(:user, :missionary, organization: organization)
        create(:user, :missionary, organization: organization)
        create(:user, :supporter, organization: organization)
        
        expect(organization.missionaries_count).to eq(2)
      end
    end

    describe '#setting' do
      it 'retrieves setting values from JSONB settings column' do
        expect(organization.setting('allow_public_profiles')).to eq(true)
        expect(organization.setting('auto_approve_missionaries')).to eq(false)
        expect(organization.setting('non_existent')).to be_nil
      end
    end

    describe '#update_setting!' do
      it 'updates a specific setting in the JSONB column' do
        organization.update_setting!('max_prayer_requests', 10)
        expect(organization.setting('max_prayer_requests')).to eq(10)
        expect(organization.settings['max_prayer_requests']).to eq(10)
      end
    end

    describe '#generate_slug' do
      it 'creates a URL-friendly slug from the name' do
        org = build(:organization, name: 'The Amazing Ministry Organization!')
        org.send(:generate_slug)
        expect(org.slug).to eq('the-amazing-ministry-organization')
      end

      it 'handles duplicate slugs by appending numbers' do
        create(:organization, name: 'Test Org', slug: 'test-org')
        
        org = build(:organization, name: 'Test Org')
        org.send(:generate_slug)
        expect(org.slug).to match(/test-org-\d+/)
      end
    end

    describe '#to_param' do
      it 'returns the slug for URL generation' do
        organization = create(:organization, slug: 'test-ministry')
        expect(organization.to_param).to eq('test-ministry')
      end
    end
  end

  
end
