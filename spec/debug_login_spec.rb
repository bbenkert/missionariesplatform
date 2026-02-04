require 'rails_helper'

RSpec.describe "Debug Login", type: :request do
  it "should access login page" do
    get "/users/sign_in"
    puts "Response status: #{response.status}"
    puts "Response headers: #{response.headers}"
    puts "Response body preview: #{response.body[0..200]}"
    
    if response.status == 403
      puts "Full response body: #{response.body}"
    end
  end
end
