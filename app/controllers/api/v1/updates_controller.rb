class Api::V1::UpdatesController < ApplicationController
  def index
    @updates = MissionaryUpdate.published.includes(:user)
                               .order(published_at: :desc)
                               .limit(50)

    render json: @updates.as_json(include: { user: { only: [:id, :name] } })
  end

  def show
    @update = MissionaryUpdate.published.includes(:user).find(params[:id])
    render json: @update.as_json(include: { user: { only: [:id, :name] } })
  end
end
