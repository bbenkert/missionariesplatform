class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index
    @total_users = User.count
    @total_missionaries = User.missionaries.count
    @approved_missionaries = User.approved_missionaries.count
    @pending_missionaries = User.missionaries.where(status: :pending).count
    @total_supporters = User.supporters.count
    @recent_users = User.order(created_at: :desc).limit(10)
    @recent_updates = MissionaryUpdate.published.recent.limit(10)
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
