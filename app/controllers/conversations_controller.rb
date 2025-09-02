class ConversationsController < ApplicationController
  before_action :require_authentication

  def index
    @conversations = current_user.sent_conversations.or(current_user.received_conversations)
                                .includes(:sender, :recipient, messages: [:sender])
                                .order(updated_at: :desc)
  end

  def show
    @conversation = current_user.sent_conversations
                                .or(current_user.received_conversations)
                                .find(params[:id])
    @messages = @conversation.messages.includes(:sender).order(created_at: :asc)
  end

  def create
    recipient = User.find(params[:recipient_id])

    # Check if conversation already exists
    @conversation = Conversation.between(current_user, recipient).first

    if @conversation.nil?
      @conversation = Conversation.create!(sender: current_user, recipient: recipient)
    end

    redirect_to @conversation
  end

  def block
    @conversation = current_user.sent_conversations
                                .or(current_user.received_conversations)
                                .find(params[:id])

    @conversation.update!(is_blocked: true, blocked_at: Time.current)
    redirect_to conversations_path, notice: 'Conversation has been blocked.'
  end

  def report
    @conversation = current_user.sent_conversations
                                .or(current_user.received_conversations)
                                .find(params[:id])

    # Implementation for reporting would go here
    redirect_to conversations_path, notice: 'Conversation has been reported.'
  end
end
