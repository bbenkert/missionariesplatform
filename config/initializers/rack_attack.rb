# Rate limiting configuration
class Rack::Attack
  # Configure cache store for Rack::Attack (must use Rails.cache in development)
  Rack::Attack.cache.store = Rails.cache
  
  # Always allow requests from localhost (for development)
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end

  # Throttle sign-in attempts by email parameter
  throttle('sign_in_email', limit: 5, period: 20.minutes) do |req|
    if req.path == '/sign_in' && req.post?
      req.params['email'].presence
    end
  end

  # Throttle sign-in attempts by IP
  throttle('sign_in_ip', limit: 10, period: 20.minutes) do |req|
    if req.path == '/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle sign-up attempts by IP
  throttle('sign_up_ip', limit: 3, period: 20.minutes) do |req|
    if req.path == '/sign_up' && req.post?
      req.ip
    end
  end

  # Throttle message sending by user
  throttle('messages_per_user', limit: 20, period: 1.hour) do |req|
    if req.path.match?(/\/conversations\/\d+\/messages/) && req.post?
      req.session[:user_id]
    end
  end

  # General request throttling by IP
  throttle('requests_by_ip', limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Block repeated password reset attempts
  throttle('password_reset', limit: 3, period: 20.minutes) do |req|
    if req.path.match?(/\/users\/password/) && req.post?
      req.params['user'].try(:[], 'email').presence || req.ip
    end
  end

  # Admin actions rate limiting
  throttle('admin_actions', limit: 50, period: 1.hour) do |req|
    if req.path.match?(/^\/admin/) && req.env['rack.session'] && req.env['rack.session'][:user_id]
      req.env['rack.session'][:user_id]
    end
  end

  # File upload limiting
  throttle('file_uploads', limit: 20, period: 1.hour) do |req|
    if req.post? && req.content_type&.include?('multipart/form-data') && req.env['rack.session']
      req.env['rack.session'][:user_id] || req.ip
    end
  end

  # Account creation limiting
  throttle('account_creation', limit: 3, period: 1.day) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end
end

# Configure response when throttled
Rack::Attack.throttled_responder = lambda do |env|
  retry_after = (env['rack.attack.match_data'] || {})[:period]
  [
    429,
    {
      'Content-Type' => 'text/plain',
      'Retry-After' => retry_after.to_s
    },
    ["Too many requests. Please wait #{retry_after} seconds before trying again.\n"]
  ]
end
