class MissionarySettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_missionary_profile

  def show
    @missionary_profile = current_user.missionary_profile
  end

  def update
    @missionary_profile = current_user.missionary_profile
    
    if @missionary_profile.update(missionary_settings_params)
      flash[:notice] = 'Privacy settings updated successfully.'
      redirect_to missionary_settings_path
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def ensure_missionary_profile
    unless current_user.missionary_profile
      flash[:alert] = 'You must have a missionary profile to access settings.'
      redirect_to root_path
    end
  end

  def missionary_settings_params
    params.require(:missionary_profile).permit(:safety_mode, :bio, :ministry_focus, :country)
  end
end
