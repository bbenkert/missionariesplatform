class UserMailer < ApplicationMailer
  def missionary_approved(user)
    @user = user
    mail(to: @user.email, subject: 'Your missionary profile has been approved!')
  end

  def missionary_registration_pending(user)
    @user = user
    mail(to: @user.email, subject: 'Welcome! Your profile is under review')
  end

  def password_reset(user)
    @user = user
    mail(to: @user.email, subject: 'Reset your password')
  end

  def weekly_digest(supporter, updates)
    @supporter = supporter
    @updates = updates
    @followed_missionaries = @supporter.followed_missionaries.includes(:missionary_profile)
    
    mail(
      to: @supporter.email,
      subject: "Weekly updates from your followed missionaries"
    )
  end

  def new_update_notification(supporter, update)
    @supporter = supporter
    @update = update
    @missionary = update.user
    
    mail(
      to: @supporter.email,
      subject: "New update from #{@missionary.name}"
    )
  end

  def new_follower(missionary, supporter)
    @missionary = missionary
    @supporter = supporter
    
    mail(
      to: @missionary.email,
      subject: "#{@supporter.name} is now following you"
    )
  end

  def new_message(message)
    @message = message
    @sender = message.sender
    @recipient = message.recipient
    
    mail(
      to: @recipient.email,
      subject: "New message from #{@sender.name}"
    )
  end
end
