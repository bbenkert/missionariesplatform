class Follow < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :followable, polymorphic: true
  
  # Validations - enforces uniqueness
  validates :user_id, uniqueness: { scope: [:followable_type, :followable_id], message: "is already following this" }
  validates :followable, presence: true
  validates :user, presence: true
  
  # Scopes
  scope :with_notifications, -> { where(notifications_enabled: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_missionaries, -> { where(followable_type: 'MissionaryProfile') }
  scope :for_organizations, -> { where(followable_type: 'Organization') }
  
  # Class methods
  def self.follow!(user:, followable:)
    create!(user: user, followable: followable)
  rescue ActiveRecord::RecordInvalid => e
    # Already following - return existing record
    find_by(user: user, followable: followable)
  end
  
  def self.unfollow!(user:, followable:)
    where(user: user, followable: followable).destroy_all.count
  end
  
  # Instance methods
  def missionary_profile?
    followable_type == 'MissionaryProfile'
  end
  
  def organization?
    followable_type == 'Organization'
  end
end
