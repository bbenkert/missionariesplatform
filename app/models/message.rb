class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'

  validates :content, presence: true, length: { maximum: 2000 }
  validates :sender, presence: true
  validates :conversation, presence: true

  # Rich text content
  has_rich_text :content

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  # Callbacks
  after_create :update_conversation_timestamp
  after_create :notify_recipient

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def recipient
    conversation.other_participant(sender)
  end

  def excerpt(limit = 100)
    content.to_plain_text.truncate(limit)
  end

  private

  def update_conversation_timestamp
    conversation.touch(:updated_at)
  end

  def notify_recipient
    return if conversation.is_blocked?
    UserMailer.new_message(self).deliver_later
  end
end
