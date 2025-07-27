module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :current_user
    helper_method :current_user, :user_signed_in?
  end

  private

  def current_user
    @current_user ||= authenticate_user_from_session
  end

  def authenticate_user_from_session
    User.find(session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end

  def user_signed_in?
    current_user.present?
  end

  def require_authentication
    unless user_signed_in?
      store_location
      redirect_to sign_in_path, alert: "Please sign in to continue."
    end
  end

  def sign_in(user)
    user.update!(last_sign_in_at: Time.current, last_sign_in_ip: request.remote_ip)
    session[:user_id] = user.id
    @current_user = user
  end

  def sign_out
    session[:user_id] = nil
    @current_user = nil
  end

  def store_location
    session[:return_to] = request.fullpath if request.get? && !request.xhr?
  end

  def redirect_back_or_to(default_path)
    redirect_to(session.delete(:return_to) || default_path)
  end
end
