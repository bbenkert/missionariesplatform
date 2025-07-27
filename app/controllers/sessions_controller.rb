class SessionsController < ApplicationController

  def new
    redirect_to dashboard_path if user_signed_in?
  end

  def create
    user = User.authenticate(params[:email], params[:password])
    
    if user
      sign_in(user)
      
      # Handle remember me functionality
      if params[:remember_me] == '1'
        # Extend session (implementation depends on your session store)
        session.options[:expire_after] = 2.weeks
      end
      
      # Redirect based on user status and role
      if user.admin?
        redirect_back_or_to(admin_root_path)
      elsif user.missionary? && user.pending?
        redirect_back_or_to(root_path, notice: "Welcome! Your missionary account is pending approval.")
      else
        redirect_back_or_to(dashboard_path)
      end
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "You have been signed out"
  end
end
