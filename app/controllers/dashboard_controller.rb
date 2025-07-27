class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    case current_user.role
    when 'admin'
      redirect_to admin_root_path
    when 'missionary'
      redirect_to missionary_dashboard_path
    when 'supporter'
      redirect_to supporter_dashboard_path
    else
      redirect_to root_path, alert: "Please complete your profile setup"
    end
  end

  private

  def missionary_dashboard_path
    # For now, redirect to missionaries index - later can be a dedicated dashboard
    missionaries_path
  end

  def supporter_dashboard_path
    # For now, redirect to missionaries index - later can be a dedicated dashboard
    missionaries_path
  end
end
