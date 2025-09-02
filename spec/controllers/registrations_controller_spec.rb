require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'GET #new' do
    context 'when user is not signed in' do
      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
        expect(assigns(:user)).to be_a_new(User)
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
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            role: 'supporter'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'signs in the user' do
        post :create, params: valid_params
        expect(controller.current_user).to be_present
        expect(controller.current_user.email).to eq('john@example.com')
      end

      context 'for supporter registration' do
        it 'redirects to dashboard with welcome message' do
          post :create, params: valid_params
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:notice]).to eq("Welcome to the missionary platform!")
        end

        it 'does not send missionary emails' do
          expect {
            post :create, params: valid_params
          }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
        end
      end

      context 'for missionary registration' do
        let(:missionary_params) do
          valid_params.deep_merge(user: { role: 'missionary' })
        end

        it 'redirects to dashboard with pending approval message' do
          post :create, params: missionary_params
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:notice]).to eq("Welcome! Your missionary profile is pending approval.")
        end

        it 'sends registration pending email to missionary' do
          expect {
            post :create, params: missionary_params
          }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('UserMailer', 'missionary_registration_pending', 'deliver_now', an_instance_of(User))
        end

        it 'sends notification email to admins' do
          expect {
            post :create, params: missionary_params
          }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'new_missionary_registration', 'deliver_now', an_instance_of(User))
        end

        it 'creates user with pending status' do
          post :create, params: missionary_params
          user = User.last
          expect(user.missionary?).to be_truthy
          expect(user.pending?).to be_truthy
        end
      end

      context 'for admin registration' do
        let(:admin_params) do
          valid_params.deep_merge(user: { role: 'admin' })
        end

        it 'creates admin user' do
          post :create, params: admin_params
          user = User.last
          expect(user.admin?).to be_truthy
          expect(user.approved?).to be_truthy
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user: {
            name: '',
            email: 'invalid-email',
            password: '123',
            password_confirmation: '123',
            role: 'supporter'
          }
        }
      end

      it 'does not create a user' do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'renders new template with errors' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:user)).to be_a_new(User).or be_invalid
      end

      it 'does not sign in the user' do
        post :create, params: invalid_params
        expect(session[:user_id]).to be_nil
      end
    end

    context 'with duplicate email' do
      let!(:existing_user) { create(:user, email: 'existing@example.com') }

      let(:duplicate_params) do
        {
          user: {
            name: 'John Doe',
            email: 'existing@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            role: 'supporter'
          }
        }
      end

      it 'does not create a user' do
        expect {
          post :create, params: duplicate_params
        }.not_to change(User, :count)
      end

      it 'renders new template with email error' do
        post :create, params: duplicate_params
        expect(response).to render_template(:new)
        expect(assigns(:user).errors[:email]).to include('has already been taken')
      end
    end

    context 'with mismatched passwords' do
      let(:mismatched_params) do
        {
          user: {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'password123',
            password_confirmation: 'different123',
            role: 'supporter'
          }
        }
      end

      it 'does not create a user' do
        expect {
          post :create, params: mismatched_params
        }.not_to change(User, :count)
      end

      it 'renders new template with password confirmation error' do
        post :create, params: mismatched_params
        expect(response).to render_template(:new)
        expect(assigns(:user).errors[:password_confirmation]).to be_present
      end
    end
  end

  describe 'private methods' do
    describe '#user_params' do
      let(:params) do
        ActionController::Parameters.new(
          user: {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            role: 'supporter',
            invalid_param: 'should be filtered out'
          }
        )
      end

      before do
        allow(controller).to receive(:params).and_return(params)
      end

      it 'permits only allowed parameters' do
        permitted = controller.send(:user_params)
        expect(permitted).to include(:name, :email, :password, :password_confirmation, :role)
        expect(permitted).not_to include(:invalid_param)
      end
    end
  end
end
