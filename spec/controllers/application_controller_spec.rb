require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    before_action :authenticate_user!
    before_action :authorize_user!
    
    def index
      render json: { message: "success" }
    end

    private

    def authorize_user!
      redirect_to dashboard_path, alert: "Not authorized" unless current_user&.admin?
    end
  end

  let!(:supporter) { create(:user, :supporter) }
  let!(:missionary) { create(:user, :missionary, status: :approved) }
  let!(:admin) { create(:user, :admin) }

  describe "Authentication" do
    it "redirects unauthenticated users to sign in" do
      get :index
      
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows authenticated users to proceed" do
      session[:user_id] = admin.id
      
      get :index
      
      expect(response).to have_http_status(:success)
    end
  end

  describe "Authorization" do
    it "redirects unauthorized users" do
      session[:user_id] = supporter.id
      
      get :index
      
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to eq("Not authorized")
    end

    it "allows authorized users" do
      session[:user_id] = admin.id
      
      get :index
      
      expect(response).to have_http_status(:success)
    end
  end

  describe "#current_user" do
    it "returns nil when no user is signed in" do
      get :index
      expect(controller.current_user).to be_nil
    end

    it "returns the current user when signed in" do
      session[:user_id] = supporter.id
      
      get :index
      expect(controller.current_user).to eq(supporter)
    end
  end

  describe "#user_signed_in?" do
    it "returns false when no user is signed in" do
      get :index
      expect(controller.user_signed_in?).to be_false
    end

    it "returns true when user is signed in" do
      session[:user_id] = supporter.id
      
      get :index
      expect(controller.user_signed_in?).to be_true
    end
  end

  describe "Devise parameter sanitization" do
    let(:params) do
      {
        user: {
          name: "Test User",
          email: "test@example.com",
          password: "SecurePassword123!",
          password_confirmation: "SecurePassword123!",
          role: "supporter",
          malicious_param: "hacker_value"
        }
      }
    end

    it "permits allowed parameters for sign up" do
      controller.params = ActionController::Parameters.new(params)
      
      permitted = controller.send(:configure_sign_up_params)
      
      expect(permitted[:name]).to eq("Test User")
      expect(permitted[:email]).to eq("test@example.com")
      expect(permitted[:role]).to eq("supporter")
      expect(permitted[:malicious_param]).to be_nil
    end

    it "permits allowed parameters for account update" do
      controller.params = ActionController::Parameters.new(params)
      
      permitted = controller.send(:configure_account_update_params)
      
      expect(permitted[:name]).to eq("Test User")
      expect(permitted[:email]).to eq("test@example.com")
      expect(permitted[:malicious_param]).to be_nil
    end
  end

  describe "Role-based redirection after sign in" do
    it "redirects supporters to dashboard" do
      expect(controller.send(:after_sign_in_path_for, supporter)).to eq(dashboard_path)
    end

    it "redirects missionaries to dashboard" do
      expect(controller.send(:after_sign_in_path_for, missionary)).to eq(dashboard_path)
    end

    it "redirects admins to admin dashboard" do
      expect(controller.send(:after_sign_in_path_for, admin)).to eq(admin_dashboard_path)
    end
  end

  describe "Error handling" do
    controller do
      def index
        raise ActiveRecord::RecordNotFound
      end
    end

    it "handles record not found errors gracefully" do
      session[:user_id] = admin.id
      
      get :index
      
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to include("not found")
    end
  end

  describe "CSRF protection" do
    it "protects against CSRF attacks" do
      expect(controller.class).to include(ActionController::RequestForgeryProtection)
    end
  end
end
