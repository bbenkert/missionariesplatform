# frozen_string_literal: true

# Security headers configuration for enhanced application security
# These headers protect against common web vulnerabilities

Rails.application.config.action_dispatch.default_headers.merge!({
  # Prevents clickjacking by disallowing the page to be displayed in frames
  'X-Frame-Options' => 'SAMEORIGIN',
  
  # Prevents MIME type sniffing
  'X-Content-Type-Options' => 'nosniff',
  
  # Enables XSS protection in browsers
  'X-XSS-Protection' => '1; mode=block',
  
  # Referrer policy - only send referrer for same-origin requests
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  
  # Permissions policy - restrict access to browser features
  'Permissions-Policy' => 'camera=(), microphone=(), geolocation=(self), payment=()'
})

# Content Security Policy
# This prevents XSS attacks by controlling which resources can be loaded
if Rails.env.production?
  Rails.application.config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https
    policy.frame_ancestors :self
    
    # Allow ActionCable connections
    policy.connect_src :self, :https, ENV.fetch('RAILS_HOST', 'localhost')
    
    # Specify URI for violation reports (optional - configure if you have a reporting endpoint)
    # policy.report_uri '/csp-violation-report-endpoint'
  end

  # Generate nonce for inline scripts (more secure than unsafe-inline)
  Rails.application.config.content_security_policy_nonce_generator = ->(request) { 
    SecureRandom.base64(16) 
  }
  
  # Report CSP violations without blocking (use for testing)
  # Rails.application.config.content_security_policy_report_only = true
end
