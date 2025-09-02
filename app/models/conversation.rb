class Conversation < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'
  has_many :messages, dependent: :destroy

  validates :sender, presence: true
  validates :recipient, presence: true
  validates :sender_id, uniqueness: { scope: :recipient_id }

  validate :different_participants
  validate :sender_can_message_recipient

  # Scopes
  scope :recent, -> { order(updated_at: :desc) }
  scope :active, -> { where(is_blocked: false) }

  def other_participant(user)
    user == sender ? recipient : sender
  end

  def last_message
    messages.order(:created_at).last
  end

  def unread_count_for(user)
    messages.where.not(sender: user).where(read_at: nil).count
  end

  def mark_as_read_for(user)
    messages.where.not(sender: user).where(read_at: nil).update_all(read_at: Time.current)
  end

  def block!
    update!(is_blocked: true, blocked_at: Time.current)
  end

  def unblock!
    update!(is_blocked: false, blocked_at: nil)
  end

  def self.between(user1, user2)
    where(
      "(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    )
  end

  def self.find_or_create_between(user1, user2)
    conversation = between(user1, user2)
    return conversation if conversation

    create!(sender: user1, recipient: user2)
  end

  private

  def different_participants
    return unless sender && recipient
    errors.add(:recipient, "can't be the same as sender") if sender == recipient
  end

  def sender_can_message_recipient
    return unless sender && recipient
    unless sender.can_message?(recipient)
      errors.add(:sender, "cannot message this user")
    end
  end
end
