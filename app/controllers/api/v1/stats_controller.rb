class Api::V1::StatsController < ApplicationController
  def index
    stats = {
      total_users: User.count,
      total_missionaries: User.missionaries.count,
      approved_missionaries: User.approved_missionaries.count,
      total_supporters: User.supporters.count,
      total_updates: MissionaryUpdate.published.count,
      countries: User.approved_missionaries.joins(:missionary_profile).distinct.pluck('missionary_profiles.country').compact.count,
      organizations: User.approved_missionaries.joins(:missionary_profile).distinct.pluck('missionary_profiles.organization').compact.count
    }

    render json: stats
  end
end
