class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index
    # System health check
    @system_health = check_system_health
    @active_sessions = count_active_sessions
    
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

  def approve_pending
    @pending_missionaries = User.missionaries
                                .joins(:missionary_profile)
                                .where(status: :pending)
                                .includes(:missionary_profile)
                                .order(created_at: :desc)
  end

  def approve_pending_missionaries
    missionary_ids = params[:missionary_ids] || []
    
    if missionary_ids.any?
      User.where(id: missionary_ids).update_all(status: :approved)
      redirect_to admin_root_path, notice: "#{missionary_ids.count} missionaries approved successfully"
    else
      redirect_to admin_approve_pending_path, alert: 'No missionaries selected'
    end
  end

  def flagged_content
    @flagged_users = User.where(status: :flagged).order(updated_at: :desc)
    @flagged_updates = MissionaryUpdate.where(status: :flagged).includes(:user).order(updated_at: :desc)
    @flagged_prayer_requests = PrayerRequest.where(status: :flagged).includes(missionary_profile: :user).order(updated_at: :desc)
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end

  def check_system_health
    health = {
      status: 'healthy',
      checks: {
        database: false,
        redis: false,
        storage: false
      },
      issues: []
    }

    # Check database connection
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      health[:checks][:database] = true
    rescue => e
      health[:status] = 'degraded'
      health[:issues] << "Database: #{e.message}"
    end

    # Check Redis connection
    begin
      if defined?(Redis) && Rails.cache.respond_to?(:redis)
        Rails.cache.redis.ping
        health[:checks][:redis] = true
      elsif defined?(Redis)
        redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/1')
        redis.ping
        redis.close
        health[:checks][:redis] = true
      else
        health[:checks][:redis] = true # Skip if Redis not configured
      end
    rescue => e
      health[:status] = 'degraded'
      health[:issues] << "Redis: #{e.message}"
    end

    # Check Active Storage
    begin
      ActiveStorage::Blob.count
      health[:checks][:storage] = true
    rescue => e
      health[:status] = 'degraded'
      health[:issues] << "Storage: #{e.message}"
    end

    # Set overall status
    if health[:issues].length >= 2
      health[:status] = 'critical'
    elsif health[:issues].any?
      health[:status] = 'degraded'
    end

    health
  end

  def count_active_sessions
    # Count users who have signed in within the last 30 minutes
    User.where('current_sign_in_at > ?', 30.minutes.ago).count
  rescue
    0
  end
end
