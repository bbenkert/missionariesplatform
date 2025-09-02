class FollowsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!
  before_action :set_followable, only: [:create, :destroy]
  
  def create
    @follow = Follow.follow!(user: current_user, followable: @followable)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "follow_button_#{dom_id(@followable)}",
          partial: 'follows/button',
          locals: { followable: @followable, current_user: current_user }
        )
      end
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: { following: true, followers_count: @followable.followers_count } }
    end
  end
  
  def destroy
    @follow_count = Follow.unfollow!(user: current_user, followable: @followable)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "follow_button_#{dom_id(@followable)}",
          partial: 'follows/button',
          locals: { followable: @followable, current_user: current_user }
        )
      end
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: { following: false, followers_count: @followable.followers_count } }
    end
  end
  
  private
  
  def set_followable
    if params[:missionary_profile_id]
      @followable = MissionaryProfile.find(params[:missionary_profile_id])
    elsif params[:organization_id]
      @followable = Organization.find(params[:organization_id])
    else
      redirect_to root_path, alert: 'Invalid follow target'
    end
  end
end
