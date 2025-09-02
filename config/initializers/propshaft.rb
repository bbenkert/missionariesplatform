# Propshaft Configuration
Rails.application.configure do
  # Propshaft paths - these are the default paths
  config.assets.paths = [
    "app/assets/builds",      # For compiled assets like TailwindCSS
    "app/assets/images",      # Images
    "app/assets/stylesheets", # Stylesheets
    "app/javascript"          # JavaScript files
  ]
  
  # Asset server in development
  if Rails.env.development?
    # Serve assets from the assets paths
    config.public_file_server.enabled = true
  end
end
