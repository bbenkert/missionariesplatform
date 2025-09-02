class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    case current_user.role
    when 'admin'
      redirect_to admin_root_path
    when 'missionary'
      redirect_to dashboard_missionary_path
    when 'supporter'
      redirect_to dashboard_supporter_path
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
                                     .where(status: 'published')
                                     .order(created_at: :desc)
                                     .limit(10)
    
    # Get latest prayer requests from both sources:
    # 1. Traditional prayer request model
    traditional_prayer_requests = PrayerRequest.includes(missionary_profile: :user)
                                              .where(missionary_profile_id: @followed_missionary_profiles.pluck(:id))
                                              .order(created_at: :desc)
                                              .limit(5)
    
    # 2. MissionaryUpdate prayer_request types
    missionary_update_prayers = MissionaryUpdate.includes(:user)
                                               .where(user_id: followed_missionary_user_ids)
                                               .where(update_type: 'prayer_request')
                                               .where(status: 'published')
                                               .order(created_at: :desc)
                                               .limit(5)
    
    # Combine and sort both types of prayer requests
    all_prayer_requests = (traditional_prayer_requests.to_a + missionary_update_prayers.to_a)
                           .sort_by(&:created_at)
                           .reverse
                           .first(8)
    
    @latest_prayer_requests = all_prayer_requests
    
    # Get statistics
    @stats = {
      following_count: @followed_missionary_profiles.count,
      total_updates: @latest_updates.count,
      total_prayer_requests: @latest_prayer_requests.count,
      prayers_offered: current_user.prayer_actions.count
    }
  end

  def missionary
    # Ensure user is a missionary
    redirect_to dashboard_path unless current_user.missionary?
    
    # Get missionary profile
    @missionary_profile = current_user.missionary_profile
    
    # Get recent updates from this missionary
    @recent_updates = current_user.missionary_updates
                                 .includes(:images_attachments)
                                 .order(created_at: :desc)
                                 .limit(10)
    
    # Get prayer requests for this missionary
    @prayer_requests = @missionary_profile&.prayer_requests
                                          &.includes(:prayer_actions)
                                          &.order(created_at: :desc)
                                          &.limit(8) || []
    
    # Get recent messages/conversations
    @recent_conversations = current_user.received_conversations
                                       .includes(:sender, :messages)
                                       .order(updated_at: :desc)
                                       .limit(8)
    
    # Get followers count
    @followers = @missionary_profile&.follows&.includes(:user) || []
    
    # Get statistics
    @stats = {
      total_updates: current_user.missionary_updates.count,
      total_prayer_requests: @prayer_requests.count,
      total_followers: @followers.count,
      total_messages: @recent_conversations.count,
      prayers_received: @prayer_requests.sum { |pr| pr.prayer_actions.count },
      urgent_prayer_requests: @prayer_requests.count { |pr| pr.is_urgent? }
    }
    
    # Get monthly statistics for charts
    @monthly_stats = {
      updates_this_month: current_user.missionary_updates.where(created_at: 1.month.ago..Time.current).count,
      prayers_this_month: @prayer_requests.select { |pr| pr.created_at > 1.month.ago }.sum { |pr| pr.prayer_actions.count },
      new_followers_this_month: @followers.count { |follow| follow.created_at > 1.month.ago }
    }
  end

  private

  def supporter_dashboard_path
    dashboard_supporter_path
  end
end
