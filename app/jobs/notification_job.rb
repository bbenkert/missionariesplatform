class NotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_type, record_id)
    case notification_type
    when 'update_published'
      notify_update_published(record_id)
    when 'new_follower'
      notify_new_follower(record_id)
    when 'new_message'
      notify_new_message(record_id)
    end
  end

  private

  def notify_update_published(update_id)
    update = MissionaryUpdate.find(update_id)
    missionary = update.user
    
    # Notify all followers who have email notifications enabled
    missionary.supporters.joins(:supporter_followings)
             .where(supporter_followings: { email_notifications: true })
             .find_each do |supporter|
      UserMailer.new_update_notification(supporter, update).deliver_now
    end
  end

  def notify_new_follower(following_id)
    following = SupporterFollowing.find(following_id)
    UserMailer.new_follower(following.missionary, following.supporter).deliver_now
  end

  def notify_new_message(message_id)
    message = Message.find(message_id)
    UserMailer.new_message(message).deliver_now
  end
end
