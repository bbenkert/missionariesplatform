require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  describe 'GET #index' do
    it 'requires authentication' do
      get :index
      expect(response).to redirect_to(sign_in_path)
    end

    context 'when user is authenticated' do
      context 'admin user' do
        let(:admin) { create(:user, :admin) }

        before do
          sign_in(admin)
        end

        it 'redirects to admin root path' do
          get :index
          expect(response).to redirect_to(admin_root_path)
        end
      end

      context 'missionary user' do
        let(:missionary) { create(:user, :missionary) }

        before do
          sign_in(missionary)
        end

        it 'redirects to missionary dashboard' do
          get :index
          expect(response).to redirect_to(missionaries_path)
        end
      end

      context 'supporter user' do
        let(:supporter) { create(:user, :supporter) }

        before do
          sign_in(supporter)
        end

        it 'redirects to supporter dashboard' do
          get :index
          expect(response).to redirect_to(missionaries_path)
        end
      end

      context 'user with unknown role' do
        let(:user) { create(:user) }

        before do
          user.update(role: 'unknown')
          sign_in(user)
        end

        it 'redirects to root path with alert' do
          get :index
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('Please complete your profile setup')
        end
      end
    end
  end

  describe 'private methods' do
    describe '#missionary_dashboard_path' do
      it 'returns missionaries path' do
        controller = DashboardController.new
        expect(controller.send(:missionary_dashboard_path)).to eq(missionaries_path)
      end
    end

    describe '#supporter_dashboard_path' do
      it 'returns missionaries path' do
        controller = DashboardController.new
        expect(controller.send(:supporter_dashboard_path)).to eq(missionaries_path)
      end
    end
  end
end
