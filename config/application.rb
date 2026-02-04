require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MissionaryPlatform
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware` subdirectories.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Host authorization for different environments
    if Rails.env.test?
      config.hosts.clear # Disable host checking in test environment
    end

    # Active Job configuration - Use inline for non-Docker, Sidekiq for Docker
    config.active_job.queue_adapter = :inline

    # Generator configurations
    config.generators do |g|
      g.test_framework :rspec
      g.factory_bot dir: 'spec/factories'
      g.view_specs false
      g.helper_specs false
      g.routing_specs false
      g.controller_specs false
      g.request_specs true
    end

    # CORS configuration for API endpoints (if needed)
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        # Only allow specific origins in production
        origins Rails.env.development? ? ['localhost:3000', '127.0.0.1:3000'] : ['https://yourdomain.com', 'https://www.yourdomain.com']
        resource '*', 
          headers: :any, 
          methods: [:get, :post, :put, :patch, :delete, :options],
          credentials: true
      end
    end

    # Rate limiting
    config.middleware.use Rack::Attack
  end
end
