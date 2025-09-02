# Puma configuration for production VPS with 2 CPUs and 8GB RAM

# Optimize for VPS with limited resources
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Preload application for memory efficiency
preload_app!

# Bind to port and host
port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }

# Restart command for systemd/docker
restart_command 'bundle exec puma'

# PID file
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Logging
stdout_redirect 'log/puma.stdout.log', 'log/puma.stderr.log', true

# Memory and process management
worker_timeout 30
worker_boot_timeout 30
worker_shutdown_timeout 30

# Memory-based worker killer (restart workers at 300MB)
before_fork do
  require 'puma_worker_killer'
  
  PumaWorkerKiller.config do |config|
    config.ram           = 300 # MB - restart worker at 300MB
    config.frequency     = 20  # seconds
    config.percent_usage = 0.98
    config.rolling_restart_frequency = 6 * 3600 # 6 hours
  end
  
  PumaWorkerKiller.start
end

# Database connection optimization
on_worker_boot do
  # Worker specific setup
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Health check endpoint
lowlevel_error_handler do |ex|
  Rack::Response.new(
    ['An error has occurred'],
    500,
    {}
  ).finish
end

# SSL configuration (if using SSL termination at Rails level)
# ssl_bind '0.0.0.0', '3000', {
#   key: ENV['SSL_KEY_PATH'],
#   cert: ENV['SSL_CERT_PATH']
# }

# Additional memory optimization
nakayoshi_fork if defined?(nakayoshi_fork)

# Bind to Unix socket for better performance (optional)
if ENV['RAILS_SOCKET']
  bind "unix://#{ENV['RAILS_SOCKET']}"
else
  bind "tcp://0.0.0.0:#{ENV.fetch('PORT') { 3000 }}"
end
