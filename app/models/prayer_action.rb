class PrayerAction < ApplicationRecord
  # Associations
  belongs_to :prayer_request
  belongs_to :user
  
  # Validations - enforces idempotency
  validates :user_id, uniqueness: { scope: :prayer_request_id, message: "has already been taken" }
  validates :prayer_request, presence: true
  validates :user, presence: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_prayer_request, ->(request) { where(prayer_request: request) }
  scope :for_user, ->(user) { where(user: user) }
  
  # Class methods
  def self.pray!(user:, prayer_request:)
    if user.nil? || prayer_request.nil?
      raise ActiveRecord::RecordInvalid.new(new(user: user, prayer_request: prayer_request))
    end
    
    existing = find_by(user: user, prayer_request: prayer_request)
    return existing if existing
    
    create!(user: user, prayer_request: prayer_request)
  rescue ActiveRecord::RecordInvalid => e
    if e.message.include?("has already been taken")
      find_by(user: user, prayer_request: prayer_request)
    else
      raise
    end
  end
  
  # Instance methods
  def summary
    "#{user.name} prayed for \"#{prayer_request.title}\""
  end
  
  def missionary_profile
    prayer_request.missionary_profile
  end
end
