module Authorization
  extend ActiveSupport::Concern

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end

  def require_missionary
    unless current_user&.missionary?
      redirect_to root_path, alert: "Access denied. Missionary account required."
    end
  end

  def require_supporter
    unless current_user&.supporter?
      redirect_to root_path, alert: "Access denied. Supporter account required."
    end
  end

  def require_missionary_or_admin
    unless current_user&.missionary? || current_user&.admin?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def authorize_user_access(user)
    unless current_user == user || current_user&.admin?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def authorize_missionary_profile_access(missionary_profile)
    unless current_user == missionary_profile.user || current_user&.admin?
      redirect_to root_path, alert: "Access denied."
    end
  end
end
