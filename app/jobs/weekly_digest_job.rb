class WeeklyDigestJob < ApplicationJob
  queue_as :default
  
  # Send weekly digest to all eligible supporters
  def perform
    email_service = EmailService.new
    
    # Get all supporters who have email notifications enabled
    eligible_users = User.supporters
                        .joins(:follows)
                        .where(is_active: true)
                        .distinct

    eligible_users.find_each do |user|
      next unless user.email_enabled?(:weekly_digest)
      
      begin
        email_service.send_weekly_digest(user)
        Rails.logger.info("Weekly digest sent to user #{user.id}")
      rescue => e
        Rails.logger.error("Failed to send weekly digest to user #{user.id}: #{e.message}")
        
        # Create notification about failed email
        Notification.create_for_user(
          user,
          :weekly_digest,
          {
            status: 'failed',
            error: e.message,
            timestamp: Time.current
          }
        )
      end
      
      # Small delay to avoid overwhelming the email service
      sleep(0.1)
    end
    
    Rails.logger.info("Weekly digest job completed for #{eligible_users.count} users")
  end
  
  # Send digest to specific user (for testing or manual triggers)
  def perform_for_user(user_id)
    user = User.find(user_id)
    email_service = EmailService.new
    
    email_service.send_weekly_digest(user)
    Rails.logger.info("Weekly digest sent to user #{user.id} (manual trigger)")
  end
end
