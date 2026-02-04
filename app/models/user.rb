class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  

  # Validations
  validates :name, presence: true

  # Enums (these automatically validate the values and generate helper methods)
  enum :role, supporter: 0, missionary: 1, admin: 2, organization_admin: 3
  enum :status, pending: 0, approved: 1, flagged: 2, suspended: 3

  # Associations
  belongs_to :organization, optional: true
  has_one :missionary_profile, dependent: :destroy
  has_many :missionary_updates, dependent: :destroy
  
  # Prayer system
  has_many :prayer_requests, through: :missionary_profile, dependent: :destroy
  has_many :prayer_actions, dependent: :destroy
  has_many :prayed_for_requests, through: :prayer_actions, source: :prayer_request
  
  # Following system (new polymorphic follows replacing old supporter_followings)
  has_many :follows, dependent: :destroy
  has_many :followed_missionaries, -> { where(follows: { followable_type: 'MissionaryProfile' }) }, 
           through: :follows, source: :followable, source_type: 'MissionaryProfile'
  has_many :followed_organizations, -> { where(follows: { followable_type: 'Organization' }) },
           through: :follows, source: :followable, source_type: 'Organization'
  
  # Legacy supporter_followings (maintain for migration period)
  has_many :supporter_followings, foreign_key: 'supporter_id', dependent: :destroy
  has_many :legacy_followed_missionaries, through: :supporter_followings, source: :missionary
  has_many :followers, class_name: 'SupporterFollowing', foreign_key: 'missionary_id', dependent: :destroy
  has_many :supporter_users, through: :followers, source: :supporter
  
  # Messaging associations
  has_many :sent_conversations, class_name: 'Conversation', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_conversations, class_name: 'Conversation', foreign_key: 'recipient_id', dependent: :destroy
  has_many :messages, foreign_key: 'sender_id', dependent: :destroy

  # Notifications and email logs
  has_many :notifications, dependent: :destroy
  has_many :email_logs, dependent: :destroy

  # File attachments
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
    attachable.variant :medium, resize_to_limit: [300, 300]
  end
  has_one_attached :banner_image do |attachable|
    attachable.variant :large, resize_to_limit: [1200, 400]
  end

  # File upload validations (Rails built-in)
  validate :avatar_content_type, if: :avatar_attached?
  validate :avatar_size, if: :avatar_attached?
  validate :banner_image_content_type, if: :banner_image_attached?
  validate :banner_image_size, if: :banner_image_attached?

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
    follows.count
  end

  def following?(followable)
    follows.exists?(followable: followable)
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

  # Notification and email preferences
  def unread_notifications_count
    notifications.unread.count
  end

  def email_preferences
    settings&.dig('email_preferences') || default_email_preferences
  end

  def default_email_preferences
    {
      'weekly_digest' => true,
      'urgent_prayers' => true,
      'new_followers' => supporter? ? false : true,
      'prayer_answered' => true,
      'missionary_updates' => supporter? ? true : false
    }
  end

  def email_enabled?(type)
    email_preferences[type.to_s] == true
  end

  def update_email_preference(type, enabled)
    current_settings = settings || {}
    current_prefs = current_settings['email_preferences'] || default_email_preferences
    current_prefs[type.to_s] = enabled
    current_settings['email_preferences'] = current_prefs
    update!(settings: current_settings)
  end

  private

  def avatar_attached?
    avatar.attached?
  end

  def banner_image_attached?
    banner_image.attached?
  end

  def avatar_content_type
    allowed_types = ['image/png', 'image/jpg', 'image/jpeg', 'image/gif', 'image/webp']
    unless allowed_types.include?(avatar.content_type)
      errors.add(:avatar, 'must be a PNG, JPG, JPEG, GIF, or WebP image')
    end
  end

  def avatar_size
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, 'must be less than 5MB')
    end
  end

  def banner_image_content_type
    allowed_types = ['image/png', 'image/jpg', 'image/jpeg', 'image/gif', 'image/webp']
    unless allowed_types.include?(banner_image.content_type)
      errors.add(:banner_image, 'must be a PNG, JPG, JPEG, GIF, or WebP image')
    end
  end

  def banner_image_size
    if banner_image.byte_size > 10.megabytes
      errors.add(:banner_image, 'must be less than 10MB')
    end
  end

  def create_missionary_profile_if_needed
    return unless missionary?
    create_missionary_profile! unless missionary_profile.present?
  end

  def notify_approval
    UserMailer.missionary_approved(self).deliver_later
  end
end
