class Admin::MissionariesController < ApplicationController
  before_action :require_admin

  def index
    missionaries_query = User.missionaries.includes(:missionary_profile)
                              .order(created_at: :desc)
    @pagy, @missionaries = pagy(missionaries_query)
  end

  def show
    @missionary = User.missionaries.includes(:missionary_profile, :missionary_updates).find(params[:id])
  end

  def update
    @missionary = User.missionaries.find(params[:id])

    if @missionary.update(missionary_params)
      redirect_to admin_missionary_path(@missionary), notice: 'Missionary updated successfully'
    else
      render :show
    end
  end

  def approve
    @missionary = User.missionaries.find(params[:id])
    @missionary.update(status: :approved)

    redirect_to admin_missionary_path(@missionary), notice: 'Missionary approved successfully'
  end

  def flag_for_review
    @missionary = User.missionaries.find(params[:id])
    @missionary.update(status: :flagged)

    redirect_to admin_missionary_path(@missionary), notice: 'Missionary flagged for review'
  end

  def toggle_visibility
    @missionary = User.missionaries.find(params[:id])
    @missionary.update(is_active: !@missionary.is_active?)

    redirect_to admin_missionary_path(@missionary), notice: 'Visibility updated successfully'
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end

  def missionary_params
    params.require(:user).permit(:status, :is_active)
  end
end
