class PrayerRequest < ApplicationRecord
  # Associations
  belongs_to :missionary_profile
  has_many :prayer_actions, dependent: :destroy
  has_many :praying_users, through: :prayer_actions, source: :user
  
  # Enums
  enum :status, { open: 0, answered: 1, closed: 2 }, prefix: true
  enum :urgency, { low: 0, medium: 1, high: 2 }, prefix: true
  
  # Validations
  validates :title, presence: true
  validates :body, presence: true
  validates :status, presence: true
  validates :urgency, presence: true
  
  # Scopes
  scope :published, -> { where(status: :open) }
  scope :recent, -> { order(created_at: :desc) }
  scope :urgent, -> { where(urgency: :high) }
  scope :by_tags, ->(tags) { where("tags @> ?", "{#{tags.join(',')}}") }
  scope :visible_to, ->(user) do
    # For public listing, only show prayer requests from public_mode missionary profiles.
    # More complex visibility rules (e.g., for followers or admins) will be handled by Pundit policies.
    joins(:missionary_profile).where(missionary_profiles: { safety_mode: :public_mode })
  end

  def self.search(query)
    where("title ILIKE ? OR body ILIKE ?", "%#{query}%", "%#{query}%")
  end

  def urgency_color
    case urgency
    when "low"
      "green"
    when "medium"
      "yellow"
    when "high"
      "orange"
    else
      "gray"
    end
  end
  
  # Callbacks
  before_save :set_published_at, if: -> { published_at.nil? && status_open? }
  before_save :update_search_vector
  
  # Instance methods
  def prayer_count
    prayer_actions.count
  end
  
  def prayed_by?(user)
    return false unless user
    prayer_actions.exists?(user: user)
  end
  
  def tag_list
    tags&.join(', ') || ''
  end
  
  def tag_list=(value)
    self.tags = value.to_s.split(',').map(&:strip).reject(&:blank?)
  end
  
  private
  
  def set_published_at
    self.published_at = Time.current
  end
  
  def update_search_vector
    self.tsvector = [title, body, tag_list].compact.join(' ')
  end
end