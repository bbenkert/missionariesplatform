# Use the official Ruby 3.4.5 image
FROM ruby:3.4.5

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy package.json and package-lock.json (if they exist)
COPY package*.json ./

# Install npm packages
RUN npm install

# Copy the rest of the application
COPY . .

# Build TailwindCSS
RUN npm run build

# Precompile assets (this will be done in development via volume mount)
# RUN rails assets:precompile

# Expose port 3000
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
