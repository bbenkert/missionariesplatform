module AuthenticationHelpers
  def sign_in(user)
    if defined?(request)
      session[:user_id] = user.id
    else
      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_button "Sign In"
    end
  end

  def sign_out
    if defined?(request)
      session[:user_id] = nil
    else
      click_button "Sign Out"
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :controller
  config.include AuthenticationHelpers, type: :system
end