module AuthenticationHelpers
  def sign_in(user)
    if respond_to?(:@request) && @request.present? # For controller specs with Devise
      sign_in user, scope: :user
    elsif defined?(request) && request.present? # For request specs
      # Use Warden test mode for request specs
      login_as(user, scope: :user) if respond_to?(:login_as)
    else
      # For system specs, manually navigate and sign in
      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password || "SecurePassword123!"
      click_button "Sign in"
    end
  end

  def sign_out
    if defined?(request)
      session[:user_id] = nil
    else
      # Find and click the sign out button/link
      if page.has_link?("Sign Out")
        click_link "Sign Out"
      elsif page.has_button?("Sign Out")
        click_button "Sign Out"
      else
        visit destroy_user_session_path
      end
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :controller
  config.include AuthenticationHelpers, type: :system
end