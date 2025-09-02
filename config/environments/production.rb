require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Cache configuration for Redis
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0'),
    expires_in: 30.minutes,
    race_condition_ttl: 10.seconds,
    namespace: 'missionary_platform_cache'
  }

  # Session store with Redis using cache store
  config.session_store :cache_store,
    key: '_missionary_platform_session',
    secure: true,
    httponly: true,
    same_site: :strict,
    expire_after: 24.hours

  # Action Cable configuration
  config.action_cable.adapter = :redis
  config.action_cable.url = ENV.fetch('REDIS_URL', 'redis://redis:6379/0')
  config.action_cable.allowed_request_origins = [
    ENV.fetch('RAILS_HOST', 'localhost'),
    /https?:\/\/#{ENV.fetch('RAILS_HOST', 'localhost')}/
  ]

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Info include generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use a different cache store in production.
  # This is already configured above with Redis

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :sidekiq
  config.active_job.queue_name_prefix = "missionary_platform_production"

  # Background job configuration
  config.active_job.default_queue_name = 'default'
  config.active_job.retry_jitter = 0.15

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts = [
    ENV.fetch('RAILS_HOST', 'localhost'),
    /.*\.#{ENV.fetch('RAILS_HOST', 'localhost').gsub('.', '\.')}/
  ]
  
  # Skip DNS rebinding protection for the default health check port.
  config.host_authorization = { exclude: ->(request) { request.path == "/health" || request.path == "/up" } }

  # Performance optimizations
  config.assets.js_compressor = :terser
  
  # File upload optimizations
  config.active_storage.variant_processor = :vips if defined?(Vips)
  
  # Database optimizations
  config.active_record.query_cache_enabled = true
  config.active_record.cache_versioning = true

  # Security headers
  config.force_ssl = true
  
  # Session configuration
  config.session_store :cookie_store,
    key: '_missionary_platform_session',
    secure: true,
    httponly: true,
    same_site: :strict,
    expire_after: 2.weeks

  # Mailer configuration
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: ENV.fetch('DOMAIN_NAME', 'yourdomain.com'), protocol: 'https' }
  
  config.action_mailer.smtp_settings = {
    address:              ENV.fetch('SMTP_SERVER', 'smtp.gmail.com'),
    port:                 ENV.fetch('SMTP_PORT', 587),
    domain:               ENV.fetch('SMTP_DOMAIN', 'yourdomain.com'),
    user_name:            ENV['SMTP_USERNAME'],
    password:             ENV['SMTP_PASSWORD'],
    authentication:       'plain',
    enable_starttls_auto: true
  }

  # Rate limiting
  config.middleware.use Rack::Attack
end
