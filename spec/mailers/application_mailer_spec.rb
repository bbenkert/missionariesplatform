require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  it 'sets the default from address' do
    expect(ApplicationMailer.default_params[:from]).to eq('noreply@missionaryplatform.com')
  end

  it 'uses the mailer layout' do
    expect(ApplicationMailer.default_params[:layout]).to eq('mailer')
  end
end
