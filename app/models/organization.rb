class Organization < ApplicationRecord
  # Associations
  has_many :users, dependent: :nullify
  has_many :missionary_profiles, dependent: :nullify
  has_many :missionaries, -> { where(role: :missionary) }, class_name: 'User'
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user
  
  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  # Callbacks
  before_validation :generate_slug, if: -> { slug.nil? && name.present? }
  
  # Scopes
  scope :active, -> { where(id: all) } # All organizations are considered active for now
  scope :by_name, -> { order(name: :asc) }
  
  def followers_count
    followers.count
  end

  def missionaries_count
    missionaries.count
  end

  def setting(key)
    settings[key]
  end

  def update_setting!(key, value)
    self.settings[key] = value
    save!
  end

  def to_param
    slug
  end

  private
  
  def generate_slug
    base_slug = name.parameterize.downcase
    slug = base_slug
    counter = 1
    
    while Organization.where(slug: slug).where.not(id: id).exists?
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = slug
  end
end
