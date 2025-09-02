require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe 'GET #new' do
    context 'when user is not signed in' do
      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context 'when user is signed in' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'redirects to dashboard' do
        get :new
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'POST #create' do
    let(:user) { create(:user, email: 'user@example.com', password: 'password123') }

    context 'with valid credentials' do
      let(:valid_params) { { email: 'user@example.com', password: 'password123' } }

      it 'signs in the user' do
        post :create, params: valid_params
        expect(controller.current_user).to eq(user)
      end

      it 'redirects admin to admin root' do
        admin = create(:user, :admin, email: 'admin@example.com', password: 'password123')
        post :create, params: { email: 'admin@example.com', password: 'password123' }
        expect(response).to redirect_to(admin_root_path)
      end

      it 'redirects pending missionary to root with notice' do
        missionary = create(:user, :missionary, :pending, email: 'missionary@example.com', password: 'password123')
        post :create, params: { email: 'missionary@example.com', password: 'password123' }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Welcome! Your missionary account is pending approval.")
      end

      it 'redirects approved user to dashboard' do
        post :create, params: valid_params
        expect(response).to redirect_to(dashboard_path)
      end

      context 'with remember me' do
        it 'extends session expiration' do
          post :create, params: valid_params.merge(remember_me: '1')
          expect(session.options[:expire_after]).to eq(2.weeks)
        end
      end

      context 'without remember me' do
        it 'does not extend session expiration' do
          post :create, params: valid_params
          expect(session.options[:expire_after]).to be_nil
        end
      end
    end

    context 'with invalid credentials' do
      let(:invalid_params) { { email: 'user@example.com', password: 'wrongpassword' } }

      it 'does not sign in the user' do
        post :create, params: invalid_params
        expect(session[:user_id]).to be_nil
      end

      it 'renders new template with alert' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
        expect(flash.now[:alert]).to eq("Invalid email or password")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-existent email' do
      let(:invalid_params) { { email: 'nonexistent@example.com', password: 'password123' } }

      it 'renders new template with alert' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
        expect(flash.now[:alert]).to eq("Invalid email or password")
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'signs out the user' do
      delete :destroy
      expect(controller.current_user).to be_nil
    end

    it 'redirects to root path with notice' do
      delete :destroy
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("You have been signed out")
    end
  end
end
nd
