class EmailLog < ApplicationRecord
  belongs_to :user

  validates :email_type, presence: true
  validates :resend_id, presence: true, uniqueness: true

  enum :email_type, {
    weekly_digest: 'weekly_digest',
    urgent_prayer: 'urgent_prayer',
    welcome: 'welcome',
    approval: 'approval',
    password_reset: 'password_reset'
  }

  scope :delivered, -> { where.not(delivered_at: nil) }
  scope :bounced, -> { where.not(bounced_at: nil) }
  scope :complained, -> { where.not(complained_at: nil) }
  scope :pending, -> { where(delivered_at: nil, bounced_at: nil, complained_at: nil) }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_type, ->(type) { where(email_type: type) }

  def delivered?
    delivered_at.present?
  end

  def bounced?
    bounced_at.present?
  end

  def complained?
    complained_at.present?
  end

  def pending?
    !delivered? && !bounced? && !complained?
  end

  def status
    return 'complained' if complained?
    return 'bounced' if bounced?
    return 'delivered' if delivered?
    'pending'
  end

  # Update status from Resend webhook
  def update_status_from_webhook(event_type, timestamp = Time.current)
    case event_type.to_s
    when 'email.delivered'
      update!(delivered_at: timestamp)
    when 'email.bounced'
      update!(bounced_at: timestamp)
    when 'email.complained'
      update!(complained_at: timestamp)
    end
  end
end
