class MissionaryUpdate < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :content, presence: true
  validates :update_type, inclusion: { in: %w[general_update prayer_request praise_report ministry_news] }

  # Enums
  enum :update_type, { general_update: 0, prayer_request: 1, praise_report: 2, ministry_news: 3 }, default: :general_update, prefix: :update
  enum :status, draft: 0, published: 1, archived: 2
  enum :visibility, { public_visibility: 0, followers_only: 1, private_visibility: 2 }, default: :public_visibility

  # Scopes
  scope :published, -> { where(status: 'published') }
  scope :recent, -> { order(created_at: :desc) }
  scope :urgent, -> { where(is_urgent: true) }
  scope :by_type, ->(type) { where(update_type: type) }
  scope :visible_to, ->(user) do
    # Public updates are always visible
    # Followers-only updates are visible to followers
    # Private updates are only visible to the owner and admins (handled by Pundit)
    # This scope is for public listing, so it primarily filters for public_visibility
    where(visibility: :public_visibility)
  end

  # File attachments
  has_many_attached :images

  # Rich text content
  has_rich_text :content

  # Callbacks
  before_save :update_tsvector
  before_save :set_published_at, if: -> { published? && published_at.nil? }
  after_create :notify_followers, if: :published?
  after_update :notify_followers, if: -> { saved_change_to_status? && published? }

  def excerpt(limit = 150)
    content.to_plain_text.truncate(limit)
  end

  def tags_list
    return [] unless tags.present?
    tags.split(',').map(&:strip).reject(&:blank?)
  end

  def tags_list=(tag_array)
    self.tags = tag_array.join(', ') if tag_array.is_a?(Array)
  end

  def type_badge_class
    case update_type
    when 'prayer_request'
      'bg-amber-100 text-amber-800'
    when 'praise_report'
      'bg-green-100 text-green-800'
    when 'ministry_news'
      'bg-blue-100 text-blue-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def urgency_badge
    return unless is_urgent?
    'bg-red-100 text-red-800'
  end

  private

  def notify_followers
    # TODO: Implement notification system without background jobs
    # NotificationJob.perform_later('update_published', self.id)
  end

  def update_tsvector
    self.tsvector = [title, content.to_plain_text].compact.join(' ')
  end

  def set_published_at
    self.published_at = Time.current
  end
end