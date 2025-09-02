class MissionaryProfile < ApplicationRecord
  belongs_to :user
  belongs_to :organization, optional: true # Ensure this is present
  has_many :prayer_requests, dependent: :destroy

  # Enums
  enum :safety_mode, { public_mode: 0, limited_mode: 1, private_mode: 2 }, default: :public_mode, prefix: :safety

  validates :user, presence: true
  validates :ministry_focus, presence: true
  validates :bio, length: { maximum: 2000 }
  validates :organization, presence: true
  validates :country, presence: true
  validates :safety_mode, presence: true

  # Followable association (polymorphic)
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user

  # Scopes
  scope :approved, -> { joins(:user).where(users: { status: 'approved' }) }
  scope :pending, -> { joins(:user).where(users: { status: 'pending' }) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_organization, ->(org) { where(organization: org) }
  scope :by_ministry_focus, ->(focus) { where(ministry_focus: focus) }
  scope :public_profiles, -> { where(safety_mode: :public_mode) }
  scope :limited_profiles, -> { where(safety_mode: :limited_mode) }
  scope :private_profiles, -> { where(safety_mode: :private_mode) }

  # Delegations
  delegate :name, :email, :avatar_url, to: :user
  delegate :approved?, :flagged?, to: :user

  def location_display
    parts = [city, country].compact.reject(&:blank?)
    parts.join(', ')
  end

  def ministry_summary
    "#{ministry_focus} - #{organization.try(:name)}" # Updated to use association
  end

  def prayer_requests_list
    prayer_requests.pluck(:body)
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
  
  def followers_count
    follows.count
  end

  # Safety mode helpers
  def visible_to?(viewer_user = nil)
    return false unless user.approved?
    
    case safety_mode
    when 'public_mode'
      true
    when 'limited_mode'
      viewer_user&.supporter? || viewer_user&.admin? || viewer_user == user
    when 'private_mode'
      viewer_user&.admin? || viewer_user == user
    else
      false
    end
  end

  def profile_data_for(viewer_user = nil)
    return nil unless visible_to?(viewer_user)
    
    case safety_mode
    when 'public_mode'
      full_profile_data
    when 'limited_mode'
      limited_profile_data
    when 'private_mode'
      viewer_user&.admin? || viewer_user == user ? full_profile_data : limited_profile_data
    end
  end

  private

  def full_profile_data
    {
      name: user.name,
      bio: bio,
      ministry_focus: ministry_focus,
      organization: organization.try(:name), # Updated to use association
      location: location_display,
      giving_links: giving_links_list,
      updates_count: updates_count,
      followers_count: followers_count
    }
  end

  def limited_profile_data
    {
      name: user.name,
      ministry_focus: ministry_focus,
      organization: organization.try(:name), # Updated to use association
      followers_count: followers_count,
      updates_count: updates_count
    }
  end
end