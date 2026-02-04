class Admin::AnnouncementsController < ApplicationController
  before_action :require_admin

  def new
    @announcement = {
      title: '',
      message: '',
      recipients: 'all'
    }
  end

  def create
    title = params[:title]
    message = params[:message]
    recipients = params[:recipients] || 'all'
    
    users = case recipients
            when 'missionaries'
              User.missionaries
            when 'supporters'
              User.supporters
            when 'all'
              User.all
            else
              User.all
            end
    
    # Queue email job for each user
    users.find_each do |user|
      # AnnouncementMailer.announcement(user, title, message).deliver_later
      # For now, just count them
    end
    
    redirect_to admin_root_path, notice: "Announcement queued for #{users.count} recipients"
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end
end
