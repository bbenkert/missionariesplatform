source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.5'

# Rails 8 with all the modern goodness
gem 'rails', '~> 8.0.0'

# Web server
gem 'puma', '~> 6.0'

# Database
gem 'pg', '~> 1.1'

# Asset pipeline and styling
gem 'propshaft'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'

# JSON handling
gem 'jbuilder'

# Redis for ActionCable and caching
gem 'redis', '~> 5.0'

# Background job processing
gem 'sidekiq', '~> 7.0'

# Performance monitoring
gem 'puma_worker_killer'

# File uploads and image processing
gem 'image_processing', '~> 1.2'

# Authentication (Rails 8 built-in)
gem 'bcrypt', '~> 3.1.7'
gem 'devise'

# Authorization
gem 'pundit', '~> 2.3'

# Pagination
gem 'pagy', '~> 6.0'

# Email
gem 'mail', '~> 2.8'
gem 'resend', '~> 0.8'

# Time zone support
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Boot time optimization
gem 'bootsnap', require: false

# Rate limiting
gem 'rack-attack', '~> 6.7'

# CORS
gem 'rack-cors', '~> 2.0'

# SEO and meta tags
gem 'meta-tags', '~> 2.18'

# Rich text content
gem 'trix-rails', require: 'trix'

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'shoulda-matchers', '~> 5.3'
end

group :development do
  gem 'web-console'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'listen', '~> 3.8'
  # gem 'annotate', '~> 3.2'  # Not compatible with Rails 8 yet
  gem 'letter_opener', '~> 1.8'
  # gem 'bullet', '~> 7.0'  # Not compatible with Rails 8 yet
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver", "~> 4.10"
  gem "webdrivers", "~> 5.3"
  gem "rails-controller-testing"
end

gem "fast-mcp", "~> 1.5"
