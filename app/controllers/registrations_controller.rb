class RegistrationsController < ApplicationController

  def new
    @user = User.new
    redirect_to dashboard_path if user_signed_in?
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      sign_in(@user)
      
      if @user.missionary?
        UserMailer.missionary_registration_pending(@user).deliver_later
        AdminMailer.new_missionary_registration(@user).deliver_later
        redirect_to dashboard_path, notice: "Welcome! Your missionary profile is pending approval."
      else
        redirect_to dashboard_path, notice: "Welcome to the missionary platform!"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end
