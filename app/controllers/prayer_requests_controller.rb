class PrayerRequestsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :authenticate_user!, only: [:pray]
  before_action :set_prayer_request, only: [:show, :edit, :update, :destroy, :pray]
  before_action :ensure_missionary_profile, only: [:new, :create, :edit, :update, :destroy]
  
  def index
    @prayer_requests = PrayerRequest.joins(:missionary_profile)
                                   .where(missionary_profiles: { safety_mode: :public_mode })
                                   .includes(:missionary_profile, :praying_users)
                                   .status_open
                                   .recent
                                   .limit(50)
    
    # Apply search filter if present
    if params[:search].present?
      @prayer_requests = @prayer_requests.search(params[:search])
    end
    
    # Apply tag filter if present
    if params[:tag].present?
      @prayer_requests = @prayer_requests.by_tags([params[:tag]])
    end
    
    # Apply urgency filter if present
    if params[:urgency].present?
      @prayer_requests = @prayer_requests.where(urgency: params[:urgency])
    end
  end

  def show
    # Check visibility based on missionary profile safety mode
    unless can_view_prayer_request?(@prayer_request)
      flash[:alert] = "You don't have permission to view this prayer request."
      redirect_to prayer_requests_path
      return
    end
    
    @prayer_action = PrayerAction.find_by(user: current_user, prayer_request: @prayer_request)
    @has_prayed = @prayer_action.present?
  end

  def new
    @prayer_request = current_user.missionary_profile.prayer_requests.build
  end

  def create
    @prayer_request = current_user.missionary_profile.prayer_requests.build(prayer_request_params)
    
    if @prayer_request.save
      flash[:notice] = 'Prayer request was successfully created.'
      redirect_to @prayer_request
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @prayer_request.missionary_profile == current_user.missionary_profile
      flash[:alert] = "You can only edit your own prayer requests."
      redirect_to prayer_requests_path
      return
    end
  end

  def update
    unless @prayer_request.missionary_profile == current_user.missionary_profile
      flash[:alert] = "You can only edit your own prayer requests."
      redirect_to prayer_requests_path
      return
    end
    
    if @prayer_request.update(prayer_request_params)
      flash[:notice] = 'Prayer request was successfully updated.'
      redirect_to @prayer_request
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @prayer_request.missionary_profile == current_user.missionary_profile
      flash[:alert] = "You can only delete your own prayer requests."
      redirect_to prayer_requests_path
      return
    end
    
    @prayer_request.destroy
    flash[:notice] = 'Prayer request was successfully deleted.'
    redirect_to prayer_requests_path
  end

  # POST /prayer_requests/:id/pray
  def pray
    unless can_view_prayer_request?(@prayer_request)
      flash[:alert] = "You don't have permission to pray for this request."
      redirect_to prayer_requests_path
      return
    end
    
    prayer_action = PrayerAction.pray!(user: current_user, prayer_request: @prayer_request)
    
    if prayer_action
      flash[:notice] = "Thank you for praying for #{@prayer_request.missionary_profile.user.name}!"
    else
      flash[:alert] = "Something went wrong. Please try again."
    end
    
    redirect_to @prayer_request
  end

  private

  def set_prayer_request
    @prayer_request = PrayerRequest.find(params[:id])
  end

  def prayer_request_params
    params.require(:prayer_request).permit(:title, :body, :urgency, :status, tag_list: [])
  end

  def ensure_missionary_profile
    unless current_user&.missionary_profile.present?
      flash[:alert] = "You need to create a missionary profile first."
      redirect_to edit_profile_path
    end
  end

  def can_view_prayer_request?(prayer_request)
    missionary_profile = prayer_request.missionary_profile
    
    case missionary_profile.safety_mode
    when 'public_mode'
      true
    when 'limited_mode'
      # Can view if following the missionary
      current_user&.follows&.where(followable: missionary_profile)&.exists? || false
    when 'private_mode'
      # Only the missionary themselves can view
      missionary_profile == current_user&.missionary_profile
    else
      false
    end
  end
end
