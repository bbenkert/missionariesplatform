class Admin::PrayerRequestsController < ApplicationController
  before_action :require_admin
  before_action :set_prayer_request, only: [:show, :update, :destroy]

  def index
    @prayer_requests = PrayerRequest.includes(:missionary_profile, :prayer_actions)
    
    # Apply status filter
    if params[:status].present? && params[:status] != 'all'
      @prayer_requests = @prayer_requests.where(status: params[:status])
    end
    
    # Apply urgency filter
    if params[:urgency].present? && params[:urgency] != 'all'
      @prayer_requests = @prayer_requests.where(urgency: params[:urgency])
    end
    
    # Apply search filter
    if params[:search].present?
      @prayer_requests = @prayer_requests.search(params[:search])
    end
    
    # Apply organization filter if present
    if params[:organization_id].present? && params[:organization_id] != 'all'
      @prayer_requests = @prayer_requests.joins(missionary_profile: :user)
                                        .where(users: { organization_id: params[:organization_id] })
    end
    
    @prayer_requests = @prayer_requests.recent.limit(100)
    
    # Stats for the index page
    @total_count = PrayerRequest.count
    @open_count = PrayerRequest.status_open.count
    @answered_count = PrayerRequest.status_answered.count
    @closed_count = PrayerRequest.status_closed.count
    @urgent_count = PrayerRequest.urgency_high.count
    
    @organizations = Organization.all
  end

  def show
    @prayer_actions = @prayer_request.prayer_actions.includes(:user).recent
  end

  def update
    if @prayer_request.update(admin_prayer_request_params)
      flash[:notice] = "Prayer request updated successfully."
      redirect_to admin_prayer_request_path(@prayer_request)
    else
      flash[:alert] = "Failed to update prayer request: #{@prayer_request.errors.full_messages.join(', ')}"
      redirect_to admin_prayer_request_path(@prayer_request)
    end
  end

  def destroy
    missionary_name = @prayer_request.missionary_profile.user.name
    title = @prayer_request.title
    
    if @prayer_request.destroy
      flash[:notice] = "Prayer request '#{title}' from #{missionary_name} has been deleted."
    else
      flash[:alert] = "Failed to delete prayer request."
    end
    
    redirect_to admin_prayer_requests_path
  end

  # Bulk actions
  def bulk_update
    prayer_request_ids = params[:prayer_request_ids]
    action = params[:bulk_action]
    
    if prayer_request_ids.blank?
      flash[:alert] = "No prayer requests selected."
      redirect_to admin_prayer_requests_path
      return
    end
    
    prayer_requests = PrayerRequest.where(id: prayer_request_ids)
    
    case action
    when 'close'
      prayer_requests.update_all(status: :closed)
      flash[:notice] = "#{prayer_requests.count} prayer requests marked as closed."
    when 'mark_answered'
      prayer_requests.update_all(status: :answered)
      flash[:notice] = "#{prayer_requests.count} prayer requests marked as answered."
    when 'reopen'
      prayer_requests.update_all(status: :open)
      flash[:notice] = "#{prayer_requests.count} prayer requests reopened."
    when 'delete'
      count = prayer_requests.count
      prayer_requests.destroy_all
      flash[:notice] = "#{count} prayer requests deleted."
    else
      flash[:alert] = "Invalid bulk action."
    end
    
    redirect_to admin_prayer_requests_path
  end

  private

  def set_prayer_request
    @prayer_request = PrayerRequest.find(params[:id])
  end

  def admin_prayer_request_params
    params.require(:prayer_request).permit(:status, :urgency)
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
