class OrganizationAdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization_admin
  before_action :load_organization
  
  def dashboard
    @stats = {
      missionaries: @organization.missionaries.approved.count,
      supporters: @organization.followers.count,
      total_updates: MissionaryUpdate.joins(user: :missionary_profile)
                                   .where(missionary_profiles: { organization: @organization })
                                   .published.count,
      prayer_requests: PrayerRequest.joins(user: :missionary_profile)
                                   .where(missionary_profiles: { organization: @organization })
                                   .active.count
    }
    
    @recent_missionaries = @organization.missionaries.joins(:missionary_profile)
                                        .includes(:missionary_profile, avatar_attachment: :blob)
                                        .approved
                                        .order(created_at: :desc)
                                        .limit(5)
    
    @recent_updates = MissionaryUpdate.joins(user: :missionary_profile)
                                     .includes(:user, user: { missionary_profile: :organization })
                                     .where(missionary_profiles: { organization: @organization })
                                     .published
                                     .order(created_at: :desc)
                                     .limit(6)
    
    @monthly_activity = calculate_monthly_activity
  end
  
  def missionaries
    missionaries_query = @organization.missionaries.joins(:missionary_profile)
                                       .includes(:missionary_profile, avatar_attachment: :blob)
                                       .order(created_at: :desc)
                                 
    @filter = params[:filter] || 'all'
    case @filter
    when 'approved'
      missionaries_query = missionaries_query.approved
    when 'pending'
      missionaries_query = missionaries_query.pending_approval
    when 'suspended'
      missionaries_query = missionaries_query.suspended
    end
    
    @pagy, @missionaries = pagy(missionaries_query)
  end
  
  def supporters
    supporters_query = @organization.followers.includes(avatar_attachment: :blob)
                                     .order(:name)
    @pagy, @supporters = pagy(supporters_query)
    
    @recent_follows = Follow.where(followable: @organization)
                           .includes(:user)
                           .order(created_at: :desc)
                           .limit(10)
  end
  
  def activity
    updates_query = MissionaryUpdate.joins(user: :missionary_profile)
                                    .includes(:user, user: { missionary_profile: :organization })
                                    .where(missionary_profiles: { organization: @organization })
                                    .order(created_at: :desc)
    
    @filter = params[:filter] || 'all'
    case @filter
    when 'published'
      updates_query = updates_query.published
    when 'draft'
      updates_query = updates_query.draft
    when 'archived'
      updates_query = updates_query.archived
    end
    
    @pagy, @updates = pagy(updates_query)
  end
  
  def settings
    if request.patch?
      if @organization.update(organization_params)
        redirect_to organization_admin_dashboard_path, notice: 'Organization settings updated successfully.'
      else
        render :settings, status: :unprocessable_entity
      end
    end
  end
  
  private
  
  def require_organization_admin
    redirect_to root_path, alert: 'Access denied.' unless current_user.organization_admin?
  end
  
  def load_organization
    @organization = current_user.organization
    redirect_to root_path, alert: 'Organization not found.' unless @organization
  end
  
  def organization_params
    params.require(:organization).permit(:name, :description, :contact_email, :website_url, :logo)
  end
  
  def calculate_monthly_activity
    # Calculate activity data for the last 12 months
    12.downto(1).map do |months_ago|
      date = months_ago.months.ago
      start_date = date.beginning_of_month
      end_date = date.end_of_month
      
      {
        month: date.strftime('%b %Y'),
        updates: MissionaryUpdate.joins(user: :missionary_profile)
                                .where(missionary_profiles: { organization: @organization })
                                .where(created_at: start_date..end_date)
                                .count,
        new_supporters: Follow.where(followable: @organization)
                             .where(created_at: start_date..end_date)
                             .count
      }
    end
  end
end
