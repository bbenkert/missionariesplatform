class Notification < ApplicationRecord
  belongs_to :user

  validates :notification_type, presence: true

  enum :notification_type, {
    new_update: 'new_update',
    urgent_prayer: 'urgent_prayer',
    new_follower: 'new_follower',
    prayer_answered: 'prayer_answered',
    missionary_approved: 'missionary_approved',
    weekly_digest: 'weekly_digest'
  }

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_type, ->(type) { where(notification_type: type) }

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end

  def mark_as_unread!
    update!(read_at: nil) if read?
  end

  # Create notification with payload
  def self.create_for_user(user, type, data = {})
    create!(
      user: user,
      notification_type: type,
      payload: data
    )
  end
end
