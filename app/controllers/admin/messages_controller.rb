class Admin::MessagesController < ApplicationController
  before_action :require_admin

  def index
    messages_query = Message.includes(:sender, :conversation)
                            .order(created_at: :desc)
    @pagy, @messages = pagy(messages_query)
  end

  def show
    @message = Message.includes(:sender, :conversation).find(params[:id])
  end

  def destroy
    @message = Message.find(params[:id])
    @message.destroy

    redirect_to admin_messages_path, notice: 'Message deleted successfully'
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
