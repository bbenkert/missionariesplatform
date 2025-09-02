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

  def supporter
    # Get followed missionary profiles
    @followed_missionary_profiles = current_user.followed_missionaries.includes(:user)
    
    # Get the users (missionaries) from these profiles
    followed_missionary_user_ids = @followed_missionary_profiles.map(&:user_id).compact
    
    # Get latest updates from followed missionaries
    @latest_updates = MissionaryUpdate.includes(:user)
                                     .where(user_id: followed_missionary_user_ids)
                                     .order(created_at: :desc)
                                     .limit(10)
    
    # Get latest prayer requests from followed missionaries
    @latest_prayer_requests = PrayerRequest.includes(:missionary_profile, :user)
                                          .where(missionary_profile_id: @followed_missionary_profiles.pluck(:id))
                                          .order(created_at: :desc)
                                          .limit(8)
    
    # Get statistics
    @stats = {
      following_count: @followed_missionary_profiles.count,
      total_updates: @latest_updates.count,
      total_prayer_requests: @latest_prayer_requests.count,
      prayers_offered: current_user.prayer_actions.count
    }
  end

  private

  def missionary_dashboard_path
    # For now, redirect to missionaries index - later can be a dedicated dashboard
    missionaries_path
  end

  def supporter_dashboard_path
    dashboard_supporter_path
  end
end
