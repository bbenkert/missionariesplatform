class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include Pagy::Backend
  
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception
  
  # Rate limiting
  include ActionController::RequestForgeryProtection
  
  # Don't require authentication for home page - let individual controllers handle it
  before_action :set_current_user
  
  private
  
  def set_current_user
    Current.user = current_user
  end
end
