module Authentication
  extend ActiveSupport::Concern

  included do
    has_secure_password
    has_secure_token :password_reset_token
    
    validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
    
    before_save :downcase_email
  end

  class_methods do
    def authenticate(email, password)
      user = find_by(email: email.downcase)
      user&.authenticate(password) ? user : nil
    end
  end

  def send_password_reset_email
    regenerate_password_reset_token
    update!(password_reset_sent_at: Time.current)
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    password_reset_sent_at < 2.hours.ago
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
