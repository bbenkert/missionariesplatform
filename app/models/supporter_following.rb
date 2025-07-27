class SupporterFollowing < ApplicationRecord
  belongs_to :supporter, class_name: 'User'
  belongs_to :missionary, class_name: 'User'

  validates :supporter, presence: true
  validates :missionary, presence: true
  validates :supporter_id, uniqueness: { scope: :missionary_id }

  # Validate that supporter is actually a supporter and missionary is actually a missionary
  validate :supporter_must_be_supporter
  validate :missionary_must_be_missionary
  validate :cannot_follow_self

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create :notify_missionary
  after_destroy :update_follower_count

  def toggle_email_notifications!
    update!(email_notifications: !email_notifications)
  end

  private

  def supporter_must_be_supporter
    return unless supporter
    errors.add(:supporter, 'must be a supporter') unless supporter.supporter?
  end

  def missionary_must_be_missionary
    return unless missionary
    errors.add(:missionary, 'must be a missionary') unless missionary.missionary?
  end

  def cannot_follow_self
    return unless supporter && missionary
    errors.add(:supporter, 'cannot follow themselves') if supporter == missionary
  end

  def notify_missionary
    UserMailer.new_follower(missionary, supporter).deliver_later
  end

  def update_follower_count
    # This could trigger a counter cache update if needed
  end
end
