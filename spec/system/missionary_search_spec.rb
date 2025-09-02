require 'rails_helper'

RSpec.describe 'Missionary Search and Filter', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
    # Create some organizations
    @org1 = create(:organization, name: 'Global Outreach', slug: 'global-outreach')
    @org2 = create(:organization, name: 'World Missions', slug: 'world-missions')

    # Create approved missionaries with diverse data
    @missionary1 = create(:user, :missionary, :approved, name: 'John Doe', email: 'john.doe@example.com', organization: @org1)
    create(:missionary_profile, user: @missionary1, bio: 'Serving in Africa, focusing on education.', country: 'Kenya', ministry_focus: 'Education', organization: @org1.name, slug: 'john-doe')

    @missionary2 = create(:user, :missionary, :approved, name: 'Jane Smith', email: 'jane.smith@example.com', organization: @org2)
    create(:missionary_profile, user: @missionary2, bio: 'Medical missions in Southeast Asia.', country: 'Thailand', ministry_focus: 'Healthcare', organization: @org2.name, slug: 'jane-smith')

    @missionary3 = create(:user, :missionary, :approved, name: 'Peter Jones', email: 'peter.jones@example.com', organization: @org1)
    create(:missionary_profile, user: @missionary3, bio: 'Church planting in South America.', country: 'Brazil', ministry_focus: 'Church Planting', organization: @org1.name, slug: 'peter-jones')

    @missionary4 = create(:user, :missionary, :approved, name: 'Alice Brown', email: 'alice.brown@example.com', organization: @org2)
    create(:missionary_profile, user: @missionary4, bio: 'Youth development in Eastern Europe.', country: 'Poland', ministry_focus: 'Youth Ministry', organization: @org2.name, slug: 'alice-brown')

    # Create a pending missionary (should not appear in search results)
    @pending_missionary = create(:user, :missionary, :pending, name: 'Pending User', email: 'pending@example.com')
    create(:missionary_profile, user: @pending_missionary, bio: 'Pending bio.', country: 'Pendingland', ministry_focus: 'Pending', organization: 'Pending Org')
  end

  it 'displays all approved missionaries by default' do
    visit missionaries_path
    expect(page).to have_content('John Doe')
    expect(page).to have_content('Jane Smith')
    expect(page).to have_content('Peter Jones')
    expect(page).to have_content('Alice Brown')
    expect(page).not_to have_content('Pending User')
  end

  context 'search functionality' do
    it 'finds missionaries by full name' do
      visit missionaries_path(search: 'John Doe')
      expect(page).to have_content('John Doe')
      expect(page).not_to have_content('Jane Smith')
    end

    it 'finds missionaries by partial name' do
      visit missionaries_path(search: 'john')
      expect(page).to have_content('John Doe')
      expect(page).not_to have_content('Jane Smith')
    end

    it 'finds missionaries by bio content' do
      visit missionaries_path(search: 'Africa education')
      expect(page).to have_content('John Doe')
      expect(page).not_to have_content('Jane Smith')
    end

    it 'finds missionaries by ministry focus' do
      visit missionaries_path(search: 'Healthcare')
      expect(page).to have_content('Jane Smith')
      expect(page).not_to have_content('John Doe')
    end

    it 'finds missionaries by organization name' do
      visit missionaries_path(search: 'Global Outreach')
      expect(page).to have_content('John Doe')
      expect(page).to have_content('Peter Jones')
      expect(page).not_to have_content('Jane Smith')
    end

    it 'finds missionaries by slug' do
      visit missionaries_path(search: 'peter-jones')
      expect(page).to have_content('Peter Jones')
      expect(page).not_to have_content('John Doe')
    end

    it 'returns no results for a non-matching search term' do
      visit missionaries_path(search: 'NonExistent')
      # Debugging: wait a bit to see if content appears
      sleep 1

      # Assert that no missionary cards are present
      expect(page).not_to have_selector('.grid.grid-cols-1.md\:grid-cols-2.lg\:grid-cols-3.gap-8.mb-8 .bg-white.rounded-lg.shadow-lg.overflow-hidden')

      # Assert the presence of the empty state message
      expect(page).to have_selector('.text-center.py-12 h3', text: 'No missionaries found')
      expect(page).to have_selector('.text-center.py-12 p', text: 'Try adjusting your search or filter criteria.')
    end
  end

  context 'filtering functionality' do
    it 'filters missionaries by country' do
      visit missionaries_path(country: 'Kenya')
      expect(page).to have_content('John Doe')
      expect(page).not_to have_content('Jane Smith')
    end

    it 'filters missionaries by organization' do
      visit missionaries_path(organization: @org2.name)
      expect(page).to have_content('Jane Smith')
      expect(page).to have_content('Alice Brown')
      expect(page).not_to have_content('John Doe')
    end

    it 'filters missionaries by ministry focus' do
      visit missionaries_path(ministry_focus: 'Church Planting')
      expect(page).to have_content('Peter Jones')
      expect(page).not_to have_content('John Doe')
    end
  end

  context 'combined search and filter' do
    it 'finds missionaries by search term and filters by country' do
      visit missionaries_path(search: 'Africa', country: 'Kenya')
      expect(page).to have_content('John Doe')
      expect(page).not_to have_content('Jane Smith')
    end

    it 'finds missionaries by search term and filters by organization' do
      visit missionaries_path(search: 'Medical', organization: @org2.name)
      expect(page).to have_content('Jane Smith')
      expect(page).not_to have_content('John Doe')
    end
  end
end
