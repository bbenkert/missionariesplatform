# Application initializer for Redis and Sidekiq configuration

# Redis configuration - use redis hostname in Docker, localhost for local development
redis_url = ENV.fetch('REDIS_URL') do
  if ENV['RAILS_ENV'] == 'development' && File.exist?('/.dockerenv')
    'redis://redis:6379/0'  # Docker internal network
  else
    'redis://localhost:6379/0'  # Local development
  end
end

# Initialize Redis connection for application use
redis_client = Redis.new(
  url: redis_url,
  timeout: 1,
  reconnect_attempts: 3
)

# Set Redis instance for application use
Rails.application.config.redis = redis_client

# Sidekiq configuration
if defined?(Sidekiq)
  Sidekiq.configure_server do |config|
    config.redis = {
      url: redis_url,
      size: 25,
      network_timeout: 5,
      pool_timeout: 1
    }
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      url: redis_url,
      size: 5,
      network_timeout: 5,
      pool_timeout: 1
    }
  end
  
  # Sidekiq Web UI configuration (production security)
  if Rails.env.production?
    require 'sidekiq/web'
    
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      # Use secure credentials for Sidekiq web access
      ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(user),
        ::Digest::SHA256.hexdigest(Rails.application.credentials.sidekiq_web_user || 'admin')
      ) && ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(password),
        ::Digest::SHA256.hexdigest(Rails.application.credentials.sidekiq_web_password || 'change_me')
      )
    end
  end
end
