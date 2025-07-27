class MissionariesController < ApplicationController
  before_action :require_authentication, except: [:index, :show]
  
  def index
    @missionaries = User.approved_missionaries
                       .includes(:missionary_profile, avatar_attachment: :blob)
                       .joins(:missionary_profile)
    
    # Filtering
    @missionaries = @missionaries.joins(:missionary_profile)
                                .where(missionary_profiles: { country: params[:country] }) if params[:country].present?
    @missionaries = @missionaries.joins(:missionary_profile)
                                .where(missionary_profiles: { organization: params[:organization] }) if params[:organization].present?
    @missionaries = @missionaries.joins(:missionary_profile)
                                .where(missionary_profiles: { ministry_focus: params[:ministry_focus] }) if params[:ministry_focus].present?
    
    # Search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @missionaries = @missionaries.joins(:missionary_profile)
                                  .where("users.name ILIKE ? OR missionary_profiles.bio ILIKE ? OR missionary_profiles.organization ILIKE ?", 
                                        search_term, search_term, search_term)
    end
    
    @pagy, @missionaries = pagy(@missionaries, items: 12)
    
    # For filters
    @countries = MissionaryProfile.joins(:user)
                                 .where(users: { status: 'approved' })
                                 .distinct
                                 .pluck(:country)
                                 .compact
                                 .sort
    @organizations = MissionaryProfile.joins(:user)
                                    .where(users: { status: 'approved' })
                                    .distinct
                                    .pluck(:organization)
                                    .compact
                                    .sort
  end

  def show
    @missionary = User.approved_missionaries.includes(:missionary_profile, :missionary_updates).find(params[:id])
    @updates = @missionary.missionary_updates.published.recent.limit(10)
    @is_following = current_user&.supporter_followings&.exists?(missionary: @missionary)
    @can_message = current_user&.can_message?(@missionary)
  rescue ActiveRecord::RecordNotFound
    redirect_to missionaries_path, alert: "Missionary not found or not approved"
  end

  def follow
    require_authentication
    return redirect_to missionaries_path, alert: "Only supporters can follow missionaries" unless current_user.supporter?
    
    @missionary = User.missionaries.find(params[:id])
    
    if current_user.supporter_followings.create(missionary: @missionary)
      respond_to do |format|
        format.html { redirect_back(fallback_location: missionary_path(@missionary), notice: "Now following #{@missionary.name}") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("follow_button", partial: "missionaries/follow_button", locals: { missionary: @missionary, is_following: true }) }
      end
    else
      redirect_back(fallback_location: missionary_path(@missionary), alert: "Unable to follow missionary")
    end
  end

  def unfollow
    require_authentication
    @missionary = User.missionaries.find(params[:id])
    following = current_user.supporter_followings.find_by(missionary: @missionary)
    
    if following&.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: missionary_path(@missionary), notice: "Unfollowed #{@missionary.name}") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("follow_button", partial: "missionaries/follow_button", locals: { missionary: @missionary, is_following: false }) }
      end
    else
      redirect_back(fallback_location: missionary_path(@missionary), alert: "Unable to unfollow missionary")
    end
  end
end
