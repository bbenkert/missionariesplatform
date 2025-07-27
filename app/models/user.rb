class User < ApplicationRecord
  # Authentication methods for models
  has_secure_password

  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :password_confirmation, presence: true, if: :password_required?

  # Generate password reset token
  before_save :downcase_email

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  # Enums (these automatically validate the values and generate helper methods)
  enum :role, supporter: 0, missionary: 1, admin: 2
  enum :status, pending: 0, approved: 1, flagged: 2, suspended: 3

  # Associations
  has_one :missionary_profile, dependent: :destroy
  has_many :missionary_updates, dependent: :destroy
  has_many :supporter_followings, foreign_key: 'supporter_id', dependent: :destroy
  has_many :followed_missionaries, through: :supporter_followings, source: :missionary
  has_many :followers, class_name: 'SupporterFollowing', foreign_key: 'missionary_id', dependent: :destroy
  has_many :supporter_users, through: :followers, source: :supporter
  
  # Messaging associations
  has_many :sent_conversations, class_name: 'Conversation', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_conversations, class_name: 'Conversation', foreign_key: 'recipient_id', dependent: :destroy
  has_many :messages, dependent: :destroy

  # File attachments
  has_one_attached :avatar
  has_one_attached :banner_image

  # Scopes
  scope :missionaries, -> { where(role: 'missionary') }
  scope :supporters, -> { where(role: 'supporter') }
  scope :admins, -> { where(role: 'admin') }
  scope :active, -> { where(is_active: true) }
  scope :approved_missionaries, -> { missionaries.where(status: 'approved') }

  # Callbacks
  # Note: Removed automatic missionary profile creation to allow manual seeding
  after_update :notify_approval, if: -> { saved_change_to_status? && approved? && missionary? }

  # Instance methods
  def full_name
    name
  end

  def display_name
    name.presence || email.split('@').first
  end

  def avatar_url(size: :medium)
    return unless avatar.attached?
    
    case size
    when :small
      avatar.variant(resize_to_fill: [50, 50])
    when :medium
      avatar.variant(resize_to_fill: [100, 100])
    when :large
      avatar.variant(resize_to_fill: [200, 200])
    else
      avatar
    end
  end

  def followers_count
    return 0 unless missionary?
    followers.count
  end

  def following_count
    return 0 unless supporter?
    supporter_followings.count
  end

  def can_message?(other_user)
    return false if self == other_user
    return false unless other_user.missionary?
    return false if blocked_by?(other_user)
    supporter? || admin?
  end

  def blocked_by?(user)
    # Implementation for blocking functionality
    false # TODO: Implement blocking
  end

  def needs_approval?
    missionary? && pending?
  end

  def public_profile?
    missionary? && approved? && is_active?
  end

  # Authentication methods
  def self.authenticate(email, password)
    user = find_by(email: email.downcase.strip)
    return nil unless user&.authenticate(password)
    user
  end

  def self.authenticate_with_email_and_password(email, password)
    user = find_by(email: email.downcase.strip)
    return nil unless user&.authenticate(password)
    return nil unless user.active?
    user
  end

  def self.find_by_password_reset_token(token)
    find_by(password_reset_token: token, password_reset_sent_at: 24.hours.ago..)
  end

  def generate_password_reset_token
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
  end

  def clear_password_reset_token!
    update!(password_reset_token: nil, password_reset_sent_at: nil)
  end

  def password_reset_expired?
    password_reset_sent_at < 24.hours.ago
  end

  def active?
    approved? && is_active?
  end

  private

  def password_required?
    password_digest.blank? || !password.blank?
  end

  def downcase_email
    self.email = email.downcase.strip if email.present?
  end

  def create_missionary_profile_if_needed
    return unless missionary?
    create_missionary_profile! unless missionary_profile.present?
  end

  def notify_approval
    UserMailer.missionary_approved(self).deliver_later
  end
end
