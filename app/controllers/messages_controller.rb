class MessagesController < ApplicationController
  before_action :require_authentication
  before_action :set_conversation

  def create
    @message = @conversation.messages.new(message_params)
    @message.sender = current_user

    if @message.save
      # Broadcast to other participant
      respond_to do |format|
        format.html { redirect_to @conversation }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @conversation, alert: 'Message could not be sent.' }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('message_form', partial: 'messages/form', locals: { conversation: @conversation, message: @message }) }
      end
    end
  end

  private

  def set_conversation
    @conversation = current_user.sent_conversations
                                .or(current_user.received_conversations)
                                .find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
