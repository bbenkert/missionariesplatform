class UpdatesController < ApplicationController
  before_action :require_authentication
  before_action :set_missionary
  before_action :set_update, only: [:show, :edit, :update, :destroy]

  def index
    @updates = @missionary.missionary_updates.published.recent
  end

  def new
    @update = @missionary.missionary_updates.new
  end

  def create
    @update = @missionary.missionary_updates.new(update_params)
    @update.user = @missionary

    if @update.save
      redirect_to missionary_path(@missionary), notice: 'Update was successfully created.'
    else
      render :new
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
    unless current_user == @missionary || current_user&.admin?
      redirect_to missionary_path(@missionary), alert: 'You are not authorized to edit this update.'
    end
  end

  def update
    # Handle draft saving
    if params[:commit] == "Save as Draft"
      @update.status = :draft
    end

    if @update.update(update_params)
      if @update.published?
        redirect_to missionary_update_path(@missionary, @update), notice: 'Update was successfully updated and published.'
      else
        redirect_to missionary_path(@missionary), notice: 'Update was saved as draft.'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @update.destroy
    redirect_to missionary_path(@missionary), notice: 'Update was successfully destroyed.'
  end

  private

  def set_missionary
    @missionary = User.missionaries.find(params[:missionary_id])
  end

  def set_update
    @update = @missionary.missionary_updates.find(params[:id])
  end

  def update_params
    params.require(:missionary_update).permit(:title, :content, :update_type, :status, :visibility, :is_urgent, :tags, images: [])
  end
end
