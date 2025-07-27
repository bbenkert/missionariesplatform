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

    # Active Job configuration
    config.active_job.queue_adapter = :sidekiq

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
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :options]
      end
    end

    # Rate limiting
    config.middleware.use Rack::Attack
  end
end
