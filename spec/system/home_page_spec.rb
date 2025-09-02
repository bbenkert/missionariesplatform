require 'rails_helper'

RSpec.describe 'Home Page', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'displays the main landing page content' do
    visit root_path

    expect(page).to have_selector('h1', text: 'Unite. Pray. Serve.')
    expect(page).to have_content('Connecting faithful supporters with missionaries around the world.')
    expect(page).to have_link('Discover Missionaries', href: missionaries_path)
    expect(page).to have_link('Join Our Community', href: sign_up_path)
    expect(page).to have_selector('h2', text: 'Why Choose Our Platform?')
    expect(page).to have_selector('h2', text: 'Start Supporting Missionaries Today')
  end
end