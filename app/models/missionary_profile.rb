class MissionaryProfile < ApplicationRecord
  belongs_to :user

  validates :user, presence: true
  validates :ministry_focus, presence: true
  validates :bio, length: { maximum: 2000 }
  validates :organization, presence: true
  validates :country, presence: true

  # Scopes
  scope :approved, -> { joins(:user).where(users: { status: 'approved' }) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_organization, ->(org) { where(organization: org) }
  scope :by_ministry_focus, ->(focus) { where(ministry_focus: focus) }

  # Delegations
  delegate :name, :email, :avatar_url, :followers_count, to: :user
  delegate :approved?, :flagged?, to: :user

  def location_display
    [city, country].compact.join(', ')
  end

  def ministry_summary
    "#{ministry_focus} - #{organization}"
  end

  def prayer_requests_list
    prayer_requests.present? ? prayer_requests.split("\n").reject(&:blank?) : []
  end

  def giving_links_list
    return [] unless giving_links.present?
    
    begin
      JSON.parse(giving_links)
    rescue JSON::ParserError
      []
    end
  end

  def updates_count
    user.missionary_updates.published.count
  end

  def recent_updates(limit = 5)
    user.missionary_updates.published.recent.limit(limit)
  end
end
