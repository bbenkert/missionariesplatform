class UpdatesController < ApplicationController
  before_action :require_authentication
  before_action :set_missionary
  before_action :set_update, only: [:show, :edit, :update, :destroy]

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
  end

  def edit
  end

  def update
    if @update.update(update_params)
      redirect_to missionary_path(@missionary), notice: 'Update was successfully updated.'
    else
      render :edit
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
    params.require(:missionary_update).permit(:title, :content, :status, :is_urgent, :tags)
  end
end
