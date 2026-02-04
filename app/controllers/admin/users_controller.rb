class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy, :approve_missionary, :suspend, :activate]

  def index
    users_query = User.includes(:missionary_profile, :organization)
                      .order(created_at: :desc)
    
    # Filtering
    users_query = users_query.where(role: params[:role]) if params[:role].present?
    users_query = users_query.where(status: params[:status]) if params[:status].present?
    users_query = users_query.where('name ILIKE ? OR email ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    
    @pagy, @users = pagy(users_query)
    
    # Stats for the dashboard
    @stats = {
      total_users: User.count,
      supporters: User.supporters.count,
      missionaries: User.missionaries.count,
      pending_missionaries: User.missionaries.pending.count,
      active_users: User.where('current_sign_in_at > ?', 30.days.ago).count,
      new_this_week: User.where('created_at > ?', 1.week.ago).count
    }
  end

  def show
    @user_activity = {
      updates_count: @user.missionary_updates.count,
      prayer_requests_count: @user.prayer_requests.count,
      followers_count: @user.missionary? ? @user.followers_count : 0,
      following_count: @user.supporter? ? @user.following_count : 0,
      recent_activity: recent_activity_for_user(@user)
    }
    
    @email_logs = @user.email_logs.recent.limit(10)
    @notifications = @user.notifications.recent.limit(10)
  end

  def edit
    # Load for editing
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_create_params)
    
    # Generate temporary password if not provided
    if params[:user][:password].blank?
      temp_password = SecureRandom.alphanumeric(12)
      @user.password = temp_password
      @user.password_confirmation = temp_password
    end
    
    if @user.save
      # TODO: Send welcome email with temporary password
      redirect_to admin_user_path(@user), notice: 'User created successfully'
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'User updated successfully'
    else
      render :show
    end
  end

  def destroy
    if @user.destroy
      redirect_to admin_users_path, notice: 'User deleted successfully.'
    else
      redirect_to admin_user_path(@user), alert: 'Failed to delete user.'
    end
  end

  def approve_missionary
    if @user.missionary? && @user.pending?
      @user.update!(status: :approved)
      
      # Send approval notification
      NotificationJob.perform_later(@user.id)
      
      redirect_to admin_user_path(@user), notice: 'Missionary approved successfully!'
    else
      redirect_to admin_user_path(@user), alert: 'Cannot approve this user.'
    end
  end

  def suspend
    @user.update!(status: :suspended, is_active: false)
    redirect_to admin_user_path(@user), notice: 'User suspended successfully.'
  end

  def activate
    @user.update!(status: :approved, is_active: true)
    redirect_to admin_user_path(@user), notice: 'User activated successfully.'
  end

  def bulk_actions
    user_ids = params[:user_ids]&.reject(&:blank?)
    action = params[:bulk_action]
    
    return redirect_to admin_users_path, alert: 'No users selected.' if user_ids.blank?
    
    users = User.where(id: user_ids)
    
    case action
    when 'approve'
      count = users.missionaries.pending.update_all(status: :approved)
      redirect_to admin_users_path, notice: "#{count} missionaries approved."
    when 'suspend'
      count = users.update_all(status: :suspended, is_active: false)
      redirect_to admin_users_path, notice: "#{count} users suspended."
    when 'activate'
      count = users.update_all(status: :approved, is_active: true)
      redirect_to admin_users_path, notice: "#{count} users activated."
    when 'delete'
      count = users.destroy_all.count
      redirect_to admin_users_path, notice: "#{count} users deleted."
    else
      redirect_to admin_users_path, alert: 'Invalid action.'
    end
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :status, :is_active, :organization_id)
  end

  def user_create_params
    params.require(:user).permit(:name, :email, :role, :status, :is_active, :organization_id, :password, :password_confirmation)
  end

  def recent_activity_for_user(user)
    activities = []
    
    # Recent updates
    activities += user.missionary_updates.recent.limit(3).map do |update|
      {
        type: 'update',
        title: update.title,
        created_at: update.created_at,
        url: missionary_update_path(update)
      }
    end
    
    # Recent prayer requests
    activities += user.prayer_requests.recent.limit(3).map do |prayer|
      {
        type: 'prayer',
        title: prayer.title,
        created_at: prayer.created_at,
        url: prayer_request_path(prayer)
      }
    end
    
    # Recent follows (for supporters)
    if user.supporter?
      activities += user.follows.recent.limit(3).includes(:followable).map do |follow|
        {
          type: 'follow',
          title: "Started following #{follow.followable.try(:user)&.display_name || follow.followable.name}",
          created_at: follow.created_at,
          url: follow.followable.try(:user) ? missionary_path(follow.followable) : organization_path(follow.followable)
        }
      end
    end
    
    activities.sort_by { |a| a[:created_at] }.reverse.first(10)
  end
end
