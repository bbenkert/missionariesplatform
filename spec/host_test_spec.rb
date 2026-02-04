require 'rails_helper'

RSpec.describe "Host Authorization Fix", type: :request do
  it "allows access to login page" do
    get "/users/sign_in"
    expect(response).to have_http_status(:success)
    expect(response.body).to include('Sign')
  end
end
