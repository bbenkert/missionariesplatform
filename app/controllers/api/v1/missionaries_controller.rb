class Api::V1::MissionariesController < ApplicationController
  def index
    @missionaries = User.approved_missionaries.includes(:missionary_profile)

    # Apply filters
    @missionaries = @missionaries.joins(:missionary_profile)
                                .where(missionary_profiles: { country: params[:country] }) if params[:country].present?
    @missionaries = @missionaries.joins(:missionary_profile)
                                .where(missionary_profiles: { organization: params[:organization] }) if params[:organization].present?

    # Search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @missionaries = @missionaries.joins(:missionary_profile)
                                  .where("users.name ILIKE ? OR missionary_profiles.bio ILIKE ? OR missionary_profiles.organization ILIKE ?",
                                        search_term, search_term, search_term)
    end

    @missionaries = @missionaries.limit(50) # Limit results

    render json: @missionaries.as_json(include: :missionary_profile)
  end

  def show
    @missionary = User.approved_missionaries.includes(:missionary_profile).find(params[:id])
    render json: @missionary.as_json(include: :missionary_profile)
  end
end
