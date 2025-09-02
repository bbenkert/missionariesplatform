class ApplicationController < ActionController::Base
  # Use both Devise authentication and our custom helpers
  include Authentication
  include Authorization
  include Pagy::Backend
  
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception
  
  # Rate limiting
  include ActionController::RequestForgeryProtection
  
  # Devise handles authentication - we just need to set current user for our Current model
  before_action :set_current_user
  
  protected
  
  # Devise redirect after sign in
  def after_sign_in_path_for(resource)
    case resource.role
    when 'admin'
      admin_root_path
    when 'organization_admin'
      organization_admin_dashboard_path
    else
      dashboard_path
    end
  end

  # Devise redirect after sign up
  def after_sign_up_path_for(resource)
    case resource.role
    when 'missionary'
      dashboard_path # They'll see pending status message
    else
      dashboard_path
    end
  end
  
  private
  
  def set_current_user
    Current.user = current_user
  end
end
