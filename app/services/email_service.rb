class EmailService
  include Rails.application.routes.url_helpers

  def initialize
    @resend = Resend::Client.new(api_key: Rails.application.credentials.resend_api_key)
  end

  def send_weekly_digest(user)
    return unless user.email_enabled?(:weekly_digest)
    
    # Get user's followed missionaries and their recent updates/prayer requests
    followed_missionaries = user.followed_missionaries.includes(:user, :missionary_updates, :prayer_requests)
    
    # Skip if no follows or no recent content
    return if followed_missionaries.empty?
    
    recent_updates = gather_recent_updates(followed_missionaries)
    urgent_prayers = gather_urgent_prayers(followed_missionaries)
    
    # Skip if no content to send
    return if recent_updates.empty? && urgent_prayers.empty?

    send_email(
      user: user,
      email_type: :weekly_digest,
      subject: "Your Weekly Mission Update - #{recent_updates.count} updates, #{urgent_prayers.count} urgent prayers",
      template: 'weekly_digest',
      data: {
        user_name: user.display_name,
        recent_updates: recent_updates,
        urgent_prayers: urgent_prayers,
        followed_count: followed_missionaries.count,
        unsubscribe_url: unsubscribe_url(user.id, token: generate_unsubscribe_token(user))
      }
    )
  end

  def send_urgent_prayer_notification(user, prayer_request)
    return unless user.email_enabled?(:urgent_prayers)
    return unless user.following?(prayer_request.missionary_profile)

    send_email(
      user: user,
      email_type: :urgent_prayer,
      subject: "🚨 Urgent Prayer Request from #{prayer_request.missionary_profile.user.display_name}",
      template: 'urgent_prayer',
      data: {
        user_name: user.display_name,
        missionary_name: prayer_request.missionary_profile.user.display_name,
        prayer_title: prayer_request.title,
        prayer_body: prayer_request.body,
        pray_url: prayer_request_url(prayer_request),
        missionary_url: missionary_profile_url(prayer_request.missionary_profile),
        unsubscribe_url: unsubscribe_url(user.id, token: generate_unsubscribe_token(user))
      }
    )
  end

  def send_welcome_email(user)
    template_name = user.missionary? ? 'welcome_missionary' : 'welcome_supporter'
    
    send_email(
      user: user,
      email_type: :welcome,
      subject: "Welcome to the Global Mission Community!",
      template: template_name,
      data: {
        user_name: user.display_name,
        role: user.role.humanize,
        dashboard_url: user.missionary? ? missionaries_dashboard_url : dashboard_url,
        getting_started_url: root_url # TODO: Create getting started page
      }
    )
  end

  def send_missionary_approval(user)
    return unless user.missionary?

    send_email(
      user: user,
      email_type: :approval,
      subject: "🎉 Your missionary account has been approved!",
      template: 'missionary_approved',
      data: {
        user_name: user.display_name,
        profile_setup_url: missionaries_dashboard_url,
        community_guidelines_url: root_url # TODO: Create guidelines page
      }
    )
  end

  # Handle Resend webhook events
  def handle_webhook(event_data)
    resend_id = event_data.dig('data', 'email_id')
    event_type = event_data['type']
    
    return unless resend_id && event_type

    email_log = EmailLog.find_by(resend_id: resend_id)
    return unless email_log

    email_log.update_status_from_webhook(event_type, Time.current)
    
    # Handle bounces and complaints
    case event_type
    when 'email.bounced'
      handle_email_bounce(email_log, event_data)
    when 'email.complained'
      handle_email_complaint(email_log, event_data)
    end
  end

  private

  def send_email(user:, email_type:, subject:, template:, data: {})
    begin
      response = @resend.emails.send(
        from: from_address,
        to: [user.email],
        subject: subject,
        html: render_email_template(template, data),
        tags: [
          { name: 'email_type', value: email_type.to_s },
          { name: 'user_role', value: user.role }
        ]
      )

      # Log the email
      EmailLog.create!(
        user: user,
        email_type: email_type,
        resend_id: response['id'],
        sent_at: Time.current,
        meta: {
          subject: subject,
          template: template,
          response: response
        }
      )

      Rails.logger.info("Email sent successfully: #{email_type} to #{user.email}")
      response

    rescue => e
      Rails.logger.error("Failed to send email: #{e.message}")
      
      # Create failed email log
      EmailLog.create!(
        user: user,
        email_type: email_type,
        resend_id: SecureRandom.uuid, # Generate temporary ID for failed sends
        meta: {
          error: e.message,
          subject: subject,
          template: template
        }
      )
      
      raise e
    end
  end

  def gather_recent_updates(followed_missionaries)
    MissionaryUpdate.joins(:missionary_profile)
                   .where(missionary_profile: followed_missionaries)
                   .where('published_at >= ?', 1.week.ago)
                   .includes(:missionary_profile => :user)
                   .order(published_at: :desc)
                   .limit(10)
  end

  def gather_urgent_prayers(followed_missionaries)
    PrayerRequest.joins(:missionary_profile)
                .where(missionary_profile: followed_missionaries)
                .where(urgency: :high, status: :open)
                .where('created_at >= ?', 1.week.ago)
                .includes(:missionary_profile => :user)
                .order(created_at: :desc)
                .limit(5)
  end

  def render_email_template(template_name, data)
    # Render email template with data
    ApplicationController.renderer.render(
      template: "user_mailer/#{template_name}",
      layout: 'mailer',
      locals: data
    )
  end

  def from_address
    "Missionary Platform <#{Rails.application.credentials.resend_from_email}>"
  end

  def generate_unsubscribe_token(user)
    # Generate secure token for unsubscribe links
    Rails.application.message_verifier(:unsubscribe).generate(user.id)
  end

  def handle_email_bounce(email_log, event_data)
    bounce_type = event_data.dig('data', 'bounce_type')
    
    # For permanent bounces, consider marking user email as invalid
    if bounce_type == 'permanent'
      user = email_log.user
      Rails.logger.warn("Permanent bounce for user #{user.id}: #{user.email}")
      
      # Could implement email validation status on User model
      # user.update(email_valid: false)
    end
  end

  def handle_email_complaint(email_log, event_data)
    user = email_log.user
    Rails.logger.warn("Email complaint from user #{user.id}: #{user.email}")
    
    # Automatically disable email notifications for this user
    user.update_email_preference(:weekly_digest, false)
    user.update_email_preference(:urgent_prayers, false)
  end
end
