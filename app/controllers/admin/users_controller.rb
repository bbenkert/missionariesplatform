class Admin::UsersController < ApplicationController
  before_action :require_admin

  def index
    @users = User.all.order(created_at: :desc).page(params[:page])
  end

  def show
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'User updated successfully'
    else
      render :show
    end
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :status, :is_active)
  end
end
