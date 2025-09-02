class NotificationJob < ApplicationJob
  queue_as :default

  # Send urgent prayer notification to all followers
  def perform(prayer_request_id)
    prayer_request = PrayerRequest.find(prayer_request_id)
    return unless prayer_request.urgency == 'high'

    email_service = EmailService.new
    missionary_profile = prayer_request.missionary_profile
    
    # Get all followers of this missionary who have urgent prayer notifications enabled
    followers = missionary_profile.followers
                                 .joins(:user)
                                 .where(users: { is_active: true })
                                 .includes(:user)

    followers.find_each do |follow|
      user = follow.user
      next unless user.email_enabled?(:urgent_prayers)
      
      begin
        # Send email notification
        email_service.send_urgent_prayer_notification(user, prayer_request)
        
        # Create in-app notification
        Notification.create_for_user(
          user,
          :urgent_prayer,
          {
            prayer_request_id: prayer_request.id,
            missionary_name: missionary_profile.user.display_name,
            prayer_title: prayer_request.title
          }
        )
        
        Rails.logger.info("Urgent prayer notification sent to user #{user.id}")
      rescue => e
        Rails.logger.error("Failed to send urgent prayer notification to user #{user.id}: #{e.message}")
      end
      
      # Small delay to avoid overwhelming the email service
      sleep(0.1)
    end
    
    Rails.logger.info("Urgent prayer notifications sent for prayer request #{prayer_request_id}")
  end

  # Legacy method compatibility - dispatch to specific methods
  def perform_legacy(notification_type, record_id)
    case notification_type
    when 'urgent_prayer'
      perform(record_id)
    when 'update_published'
      notify_update_published(record_id)
    when 'new_follower'
      notify_new_follower(record_id)
    when 'new_message'
      notify_new_message(record_id)
    when 'prayer_answered'
      notify_prayer_answered(record_id)
    end
  end

  # Send welcome email to new user
  def perform_welcome_email(user_id)
    user = User.find(user_id)
    email_service = EmailService.new
    
    begin
      email_service.send_welcome_email(user)
      Rails.logger.info("Welcome email sent to user #{user.id}")
    rescue => e
      Rails.logger.error("Failed to send welcome email to user #{user.id}: #{e.message}")
    end
  end

  # Send missionary approval notification
  def perform_missionary_approval(user_id)
    user = User.find(user_id)
    return unless user.missionary? && user.approved?
    
    email_service = EmailService.new
    
    begin
      email_service.send_missionary_approval(user)
      
      # Create in-app notification
      Notification.create_for_user(
        user,
        :missionary_approved,
        {
          message: "Your missionary account has been approved! You can now set up your profile.",
          approved_at: user.updated_at
        }
      )
      
      Rails.logger.info("Missionary approval notification sent to user #{user.id}")
    rescue => e
      Rails.logger.error("Failed to send missionary approval notification to user #{user.id}: #{e.message}")
    end
  end

  # Notify missionary of new follower
  def perform_new_follower_notification(follow_id)
    follow = Follow.find(follow_id)
    return unless follow.followable_type == 'MissionaryProfile'
    
    missionary_profile = follow.followable
    missionary_user = missionary_profile.user
    follower = follow.user
    
    return unless missionary_user.email_enabled?(:new_followers)
    
    begin
      # Create in-app notification
      Notification.create_for_user(
        missionary_user,
        :new_follower,
        {
          follower_id: follower.id,
          follower_name: follower.display_name,
          followed_at: follow.created_at
        }
      )
      
      Rails.logger.info("New follower notification sent to user #{missionary_user.id}")
    rescue => e
      Rails.logger.error("Failed to send new follower notification to user #{missionary_user.id}: #{e.message}")
    end
  end

  private

  def notify_update_published(update_id)
    # Legacy method - could implement email notifications for new updates
    update = MissionaryUpdate.find(update_id)
    Rails.logger.info("Update published notification for update #{update_id}")
  end

  def notify_new_follower(follow_id)
    perform_new_follower_notification(follow_id)
  end

  def notify_new_message(message_id)
    # Legacy method - could implement message notifications
    Rails.logger.info("New message notification for message #{message_id}")
  end

  def notify_prayer_answered(prayer_request_id)
    prayer_request = PrayerRequest.find(prayer_request_id)
    
    # Notify all supporters who prayed for this request
    prayer_request.prayer_actions.includes(:user).find_each do |prayer_action|
      user = prayer_action.user
      next unless user.email_enabled?(:prayer_answered)
      
      Notification.create_for_user(
        user,
        :prayer_answered,
        {
          prayer_request_id: prayer_request.id,
          prayer_title: prayer_request.title,
          missionary_name: prayer_request.missionary_profile.user.display_name
        }
      )
    end
  end
end
