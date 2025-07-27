class WeeklyDigestJob < ApplicationJob
  queue_as :default

  def perform
    User.supporters.joins(:supporter_followings)
        .where(supporter_followings: { email_notifications: true })
        .distinct
        .find_each do |supporter|
      
      # Get updates from the last week for followed missionaries
      updates = MissionaryUpdate.published
                               .joins(user: { followers: :supporter })
                               .where(supporter_followings: { supporter: supporter })
                               .where('missionary_updates.created_at >= ?', 1.week.ago)
                               .includes(user: :missionary_profile)
                               .order(:created_at)

      next if updates.empty?

      UserMailer.weekly_digest(supporter, updates).deliver_now
    end
  end
end
