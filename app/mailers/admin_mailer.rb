class AdminMailer < ApplicationMailer
  def new_missionary_registration(user)
    @user = user
    @admin_emails = User.admins.pluck(:email)
    
    mail(
      to: @admin_emails,
      subject: 'New missionary registration requires approval'
    )
  end

  def reported_message(message, reporter)
    @message = message
    @reporter = reporter
    @admin_emails = User.admins.pluck(:email)
    
    mail(
      to: @admin_emails,
      subject: 'Message reported for review'
    )
  end
end
