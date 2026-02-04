require 'rails_helper'

RSpec.describe "User Authentication", type: :request do
  let(:user) do
    create(:user, email: 'user@example.com', password: "SecurePassword123!", password_confirmation: "SecurePassword123!")
  end
  
  let(:admin) do
    create(:user, :admin, email: 'admin@example.com', password: "SecurePassword123!", password_confirmation: "SecurePassword123!")
  end

  describe 'GET /users/sign_in' do
    context 'when user is not signed in' do
      it 'renders the sign in page' do
        get new_user_session_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Sign In')
      end
    end

    context 'when user is already signed in' do
      before { sign_in(user) }

      it 'redirects to dashboard' do
        get new_user_session_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'POST /users/sign_in' do
    context 'with valid credentials' do
      it 'signs in the user and redirects to dashboard' do
        post user_session_path, params: {
          user: { email: user.email, password: "SecurePassword123!" }
        }
        expect(response).to redirect_to(dashboard_path)
      end

      it 'redirects admin to admin dashboard' do
        post user_session_path, params: {
          user: { email: admin.email, password: "SecurePassword123!" }
        }
        expect(response).to redirect_to(admin_root_path)
      end
    end

    context 'with invalid credentials' do
      it 'renders sign in page with error' do
        post user_session_path, params: {
          user: { email: user.email, password: 'wrong_password' }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    before { sign_in(user) }

    it 'signs out the user' do
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
