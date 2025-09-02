# Configure Sidekiq
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# Schedule weekly digest job (sidekiq-cron not available)
# if defined?(Rails::Server)
#   require 'sidekiq-cron'
#   
#   Sidekiq::Cron::Job.create(
#     name: 'Weekly Digest',
#     description: 'Send weekly digest emails to supporters',
#     cron: '0 9 * * 0', # Every Sunday at 9 AM
#     class: 'WeeklyDigestJob'
#   )
# end
