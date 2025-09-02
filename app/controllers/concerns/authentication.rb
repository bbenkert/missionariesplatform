module Authentication
  extend ActiveSupport::Concern

  # This module now works with Devise's authentication
  # Devise provides current_user method, we just add some helper methods

  def user_signed_in?
    current_user.present?
  end

  def require_authentication
    unless user_signed_in?
      store_location
      redirect_to new_user_session_path, alert: "Please sign in to continue."
    end
  end

  def custom_sign_out
    # Use Devise's sign_out method
    sign_out(current_user) if current_user
  end

  def store_location
    store_location_for(:user, request.fullpath) if request.get? && !request.xhr?
  end

  def redirect_back_or_to(default_path)
    redirect_to(stored_location_for(:user) || default_path)
    clear_stored_location_for(:user)
  end
end
