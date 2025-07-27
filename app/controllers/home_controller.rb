class HomeController < ApplicationController
  def index
    @stats = Rails.cache.fetch("platform_stats", expires_in: 1.hour) do
      {
        active_missionaries: User.approved_missionaries.count,
        countries_reached: MissionaryProfile.joins(:user)
                                          .where(users: { status: 'approved' })
                                          .distinct
                                          .count(:country),
        total_supporters: User.supporters.count,
        total_updates: MissionaryUpdate.published.count,
        recent_updates: MissionaryUpdate.published
                                      .includes(user: :missionary_profile)
                                      .recent
                                      .limit(6)
      }
    end

    @featured_missionaries = User.approved_missionaries
                                .includes(:missionary_profile)
                                .joins(:missionary_profile)
                                .limit(3)
  end
end
