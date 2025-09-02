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

  def new
    @recipient = User.find(params[:recipient_id])
    @conversation = Conversation.new
  end

  def create
    # Get recipient_id from the nested conversation params
    recipient_id = params[:conversation][:recipient_id] || params[:recipient_id]
    recipient = User.find(recipient_id)

    # Check if conversation already exists
    @conversation = Conversation.between(current_user, recipient).first

    if @conversation.nil?
      @conversation = Conversation.create!(sender: current_user, recipient: recipient)
    end

    # Create the initial message if content is provided
    if params[:conversation][:content].present?
      @conversation.messages.create!(
        sender: current_user,
        content: params[:conversation][:content]
      )
    end

    redirect_to @conversation, notice: 'Message sent successfully!'
  rescue ActiveRecord::RecordNotFound => e
    redirect_to conversations_path, alert: 'User not found.'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to conversations_path, alert: "Error creating conversation: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    # Find recipient for error handling
    recipient_id = params[:conversation][:recipient_id] || params[:recipient_id]
    @recipient = User.find(recipient_id) rescue nil
    @conversation = Conversation.new
    flash.now[:alert] = "There was an error sending your message: #{e.message}"
    render :new
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
