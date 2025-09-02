class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index
    # User statistics
    @total_users = User.count
    @total_missionaries = User.where(role: :missionary).count
    @total_supporters = User.where(role: :supporter).count
    @approved_missionaries = MissionaryProfile.approved.count
    @pending_missionaries = MissionaryProfile.pending.count
    @recent_users = User.order(created_at: :desc).limit(5)
    
    # Prayer request statistics
    @total_prayer_requests = PrayerRequest.count
    @open_prayer_requests = PrayerRequest.where(status: :open).count
    @urgent_prayer_requests = PrayerRequest.where(urgency: :high).count
    @total_prayer_actions = PrayerAction.count
    @recent_prayer_requests = PrayerRequest.includes(missionary_profile: :user)
                                           .order(created_at: :desc)
                                           .limit(5)
    @most_prayed_requests = PrayerRequest.includes(missionary_profile: :user)
                                         .joins(:prayer_actions)
                                         .group('prayer_requests.id')
                                         .order('COUNT(prayer_actions.id) DESC')
                                         .limit(5)
    
    # Organization statistics
    @total_organizations = Organization.count
    @recent_organizations = Organization.order(created_at: :desc).limit(5)
    
    # Follow statistics  
    @total_follows = Follow.count
    @recent_follows = Follow.includes(:user, :followable).order(created_at: :desc).limit(5)
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
