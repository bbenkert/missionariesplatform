require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  include Rails.application.routes.url_helpers
  default_url_options[:host] = 'localhost:3000'

  describe "missionary_approved" do
    let(:missionary) { create(:user, :missionary, :approved, name: 'John Missionary', email: 'john@example.com') }
    let(:mail) { UserMailer.missionary_approved(missionary) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Your missionary profile has been approved!')
      expect(mail.to).to eq(['john@example.com'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('John Missionary')
      expect(mail.body.encoded).to include('approved')
    end
  end

  describe '#missionary_registration_pending' do
    let(:missionary) { create(:user, :missionary, :pending, name: 'Jane Missionary', email: 'jane@example.com') }
    let(:mail) { UserMailer.missionary_registration_pending(missionary) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Welcome! Your profile is under review')
      expect(mail.to).to eq(['jane@example.com'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Jane Missionary')
      expect(mail.body.encoded).to include('under review')
    end
  end

  describe '#password_reset' do
    let(:user) { create(:user, name: 'John Doe', email: 'john@example.com') }
    let(:mail) { UserMailer.password_reset(user) }

    before do
      user.generate_password_reset_token
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Reset your password')
      expect(mail.to).to eq(['john@example.com'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('John Doe')
      expect(mail.body.encoded).to include('reset')
    end
  end

  describe '#weekly_digest' do
    let(:supporter) { create(:user, :supporter, name: 'Supporter User', email: 'supporter@example.com') }
    let(:missionary1) { create(:user, :missionary, :approved, name: 'Missionary One') }
    let(:missionary2) { create(:user, :missionary, :approved, name: 'Missionary Two') }
    let(:update1) { create(:missionary_update, user: missionary1, title: 'Update 1') }
    let(:update2) { create(:missionary_update, user: missionary2, title: 'Update 2') }
    let(:updates) { [update1, update2] }
    let(:mail) { UserMailer.weekly_digest(supporter, updates) }

    before do
      create(:supporter_following, supporter: supporter, missionary: missionary1)
      create(:supporter_following, supporter: supporter, missionary: missionary2)
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Weekly updates from your followed missionaries')
      expect(mail.to).to eq(['supporter@example.com'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Supporter User')
      expect(mail.body.encoded).to include('Update 1')
      expect(mail.body.encoded).to include('Update 2')
    end
  end

  describe '#new_update_notification' do
    let(:supporter) { create(:user, :supporter, name: 'Supporter User', email: 'supporter@example.com') }
    let(:missionary) { create(:user, :missionary, :approved, name: 'Missionary User') }
    let(:update) { create(:missionary_update, user: missionary, title: 'New Update', content: 'Update content') }
    let(:mail) { UserMailer.new_update_notification(supporter, update) }

    it 'renders the headers' do
      expect(mail.subject).to eq('New update from Missionary User')
      expect(mail.to).to eq(['supporter@example.com'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Supporter User')
      expect(mail.body.encoded).to include('Missionary User')
      expect(mail.body.encoded).to include('New Update')
    end
  end

  describe '#new_follower' do
    let(:missionary) { create(:user, :missionary, :approved, name: 'Missionary User', email: 'missionary@example.com') }
    let(:supporter) { create(:user, :supporter, name: 'Supporter User') }
    let(:mail) { UserMailer.new_follower(missionary, supporter) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Supporter User is now following you')
      expect(mail.to).to eq(['missionary@example.com'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Missionary User')
      expect(mail.body.encoded).to include('Supporter User')
    end
  end

  describe '#new_message' do
    let(:sender) { create(:user, :supporter, name: 'Sender User') }
    let(:recipient) { create(:user, :missionary, :approved, name: 'Recipient User', email: 'recipient@example.com') }
    let(:conversation) { create(:conversation, sender: sender, recipient: recipient) }
    let(:message) { create(:message, conversation: conversation, sender: sender, content: 'Hello there!') }
    let(:mail) { UserMailer.new_message(message) }

    it 'renders the headers' do
      expect(mail.subject).to eq('New message from Sender User')
      expect(mail.to).to eq(['recipient@example.com'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Sender User')
      expect(mail.body.encoded).to include('Recipient User')
      expect(mail.body.encoded).to include('Hello there!')
    end
  end
end
