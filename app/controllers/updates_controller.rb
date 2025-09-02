class UpdatesController < ApplicationController
  before_action :require_authentication
  before_action :set_missionary
  before_action :set_update, only: [:show, :edit, :update, :destroy]

  def index
    if @missionary
      # Nested route: /missionaries/:missionary_id/updates
      @updates = @missionary.missionary_updates.published.recent
    else
      # Standalone route: /updates (for current user's updates)
      redirect_to root_path, alert: 'Access denied.' unless current_user.missionary?
      @updates = current_user.missionary_updates.recent
      @missionary = current_user
    end
  end

  def new
    redirect_to root_path, alert: 'Access denied.' unless current_user.missionary?
    @missionary = current_user
    @update = current_user.missionary_updates.new
  end

  def create
    redirect_to root_path, alert: 'Access denied.' unless current_user.missionary?
    @missionary = current_user
    @update = current_user.missionary_updates.new(update_params)

    # Handle draft saving
    if params[:commit] == "Save as Draft"
      @update.status = :draft
    end

    if @update.save
      if @update.published?
        redirect_to dashboard_missionary_path, notice: 'Update was successfully created and published.'
      else
        redirect_to dashboard_missionary_path, notice: 'Update was saved as draft.'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Ensure the update is published and visible
    unless @update.published? && (@update.public_visibility? || current_user == @missionary || current_user&.admin?)
      redirect_to missionary_path(@missionary), alert: 'Update not found or not accessible.'
    end
  end

  def edit
    # Ensure only the missionary or admin can edit
    unless current_user == @update.user || current_user&.admin?
      redirect_to dashboard_missionary_path, alert: 'You are not authorized to edit this update.'
    end
    @missionary = @update.user
  end

  def update
    # Ensure only the missionary or admin can edit
    unless current_user == @update.user || current_user&.admin?
      redirect_to dashboard_missionary_path, alert: 'You are not authorized to edit this update.'
    end
    
    @missionary = @update.user

    # Handle draft saving
    if params[:commit] == "Save as Draft"
      @update.status = :draft
    end

    if @update.update(update_params)
      if @update.published?
        redirect_to dashboard_missionary_path, notice: 'Update was successfully updated and published.'
      else
        redirect_to dashboard_missionary_path, notice: 'Update was saved as draft.'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Ensure only the missionary or admin can delete
    unless current_user == @update.user || current_user&.admin?
      redirect_to dashboard_missionary_path, alert: 'You are not authorized to delete this update.'
      return
    end
    
    @update.destroy
    redirect_to dashboard_missionary_path, notice: 'Update was successfully deleted.'
  end

  private

  def set_missionary
    if params[:missionary_id]
      # Nested route: /missionaries/:missionary_id/updates
      @missionary = User.missionaries.find(params[:missionary_id])
    else
      # Standalone route: /updates (for current user)
      @missionary = current_user if current_user&.missionary?
    end
  end

  def set_update
    if @missionary
      @update = @missionary.missionary_updates.find(params[:id])
    else
      # For standalone routes, find updates belonging to current user
      @update = current_user.missionary_updates.find(params[:id])
    end
  end

  def update_params
    params.require(:missionary_update).permit(:title, :content, :update_type, :status, :visibility, :is_urgent, :tags, images: [])
  end
end
