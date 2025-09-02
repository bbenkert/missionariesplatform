class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  

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
  has_many :prayer_requests, dependent: :destroy
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

  private

  def create_missionary_profile_if_needed
    return unless missionary?
    create_missionary_profile! unless missionary_profile.present?
  end

  def notify_approval
    UserMailer.missionary_approved(self).deliver_later
  end
end
