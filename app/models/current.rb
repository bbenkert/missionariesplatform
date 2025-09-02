class Current < ActiveSupport::CurrentAttributes
  attribute :user

  def user=(user)
    super
    Time.zone = user&.time_zone if user&.respond_to?(:time_zone)
  end
end
