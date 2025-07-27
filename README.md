# Missionary Platform - Rails 8

A comprehensive Ruby on Rails platform connecting missionaries with their support networks worldwide. Built with Rails 8, PostgreSQL, Tailwind CSS, and modern best practices.

## 🌟 Features

### Core Functionality
- **Multi-role Authentication**: Admin, Missionary, and Supporter roles with scoped dashboards
- **Missionary Profiles**: Comprehensive profiles with bio, ministry focus, location, and prayer requests
- **Profile Approval System**: Admin review and approval workflow for new missionary registrations
- **Real-time Following System**: Supporters can follow missionaries and receive updates
- **Messaging System**: Private messaging between supporters and missionaries
- **Prayer Updates**: Missionaries can post updates, prayer requests, and praise reports
- **Email Notifications**: Weekly digest emails and instant notifications

### Admin Features
- **Admin Dashboard**: Review pending profiles, manage users, and monitor platform activity
- **Profile Management**: Approve, flag, or suspend missionary profiles
- **Content Moderation**: Review reported messages and manage user interactions
- **Platform Statistics**: Monitor user growth, engagement, and platform health

### Communication & Engagement
- **Update Types**: General updates, prayer requests, praise reports, and ministry news
- **Rich Text Content**: Enhanced text editing with ActionText
- **Image Uploads**: Profile photos and update images with ActiveStorage
- **Weekly Email Digests**: Automated weekly summaries for supporters
- **Real-time Notifications**: Instant alerts for new messages and updates

### Security & Privacy
- **Rate Limiting**: Protection against spam and abuse using Rack::Attack
- **Secure Messaging**: Private conversations with blocking and reporting features
- **CSRF Protection**: Built-in Rails security features
- **Input Validation**: Comprehensive form validation and sanitization
- **Privacy Controls**: User-controlled notification preferences

## 🚀 Tech Stack

- **Backend**: Ruby on Rails 8.0 with modern conventions
- **Database**: PostgreSQL 16 with optimized indexing
- **Styling**: Tailwind CSS 3.3 with custom components
- **Background Jobs**: Sidekiq with Redis for async processing
- **File Storage**: ActiveStorage with image processing
- **Real-time Features**: Hotwire (Turbo + Stimulus) for dynamic interactions
- **Email**: ActionMailer with background delivery
- **Testing**: RSpec with FactoryBot and Capybara
- **Deployment**: Docker with Docker Compose for development

## 📋 Prerequisites

- Docker and Docker Compose
- Git

## 🛠 Installation & Setup

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd missionary_platform_in_rails

# Build and start all services
docker-compose up --build
```

### 2. Database Setup
```bash
# Create and migrate database
docker-compose exec web rails db:create db:migrate

# Seed with sample data
docker-compose exec web rails db:seed
```

### 3. Access the Application
- **Web Application**: http://localhost:3000
- **Sidekiq Dashboard**: http://localhost:3000/sidekiq (admin only)

### Sample Accounts
After seeding, you can log in with:
- **Admin**: admin@missionaryplatform.com / password123
- **Supporter**: supporter1@example.com / password123  
- **Missionary**: missionary1@example.com / password123

## 🏗 Development

### Starting Services
```bash
# Start all services in background
docker-compose up -d

# View logs
docker-compose logs -f web

# Stop services
docker-compose down
```

### Running Commands
```bash
# Rails console
docker-compose exec web rails console

# Run tests
docker-compose exec web rspec

# Generate migration
docker-compose exec web rails generate migration AddFieldToModel field:type

# Install gems
docker-compose exec web bundle install
```

### Database Operations
```bash
# Run migrations
docker-compose exec web rails db:migrate

# Reset database
docker-compose exec web rails db:drop db:create db:migrate db:seed

# Create migration
docker-compose exec web rails generate migration CreateNewModel
```

## 📊 Background Jobs

The platform uses Sidekiq for background processing:

### Weekly Digest Job
Automatically sends weekly email summaries to supporters every Sunday at 9 AM.

### Notification Jobs
- New follower notifications
- New message alerts  
- Update publication notifications
- Admin approval notifications

### Running Jobs Manually
```bash
# Start weekly digest for all users
docker-compose exec web rails runner "WeeklyDigestJob.perform_now"

# Process specific notification
docker-compose exec web rails runner "NotificationJob.perform_now('update_published', 1)"
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
docker-compose exec web rspec

# Run specific test file
docker-compose exec web rspec spec/models/user_spec.rb

# Run tests with coverage
docker-compose exec web rspec --format documentation
```

### Test Structure
- **Model Tests**: Validations, associations, and business logic
- **Request Tests**: Controller actions and API endpoints
- **System Tests**: Full browser integration tests
- **Feature Tests**: User workflow testing

## 🔐 Security Features

### Authentication & Authorization
- Secure password hashing with bcrypt
- Role-based access control (RBAC)
- Friendly forwarding after login
- Session-based authentication

### Rate Limiting
- Message sending limits
- API request throttling
- Login attempt protection

### Content Security
- CSRF protection on all forms
- Input sanitization and validation
- Secure file upload handling
- XSS prevention

### Privacy Controls
- Private messaging system
- User blocking and reporting
- Content moderation tools
- GDPR-friendly data handling

## 📈 Deployment

### Production Setup
```bash
# Set environment variables
export DATABASE_URL="postgresql://user:pass@host:5432/db"
export REDIS_URL="redis://host:6379/0"
export RAILS_ENV=production

# Build for production
docker-compose -f docker-compose.prod.yml up --build
```

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db_name
DB_HOST=localhost
DB_USERNAME=postgres
DB_PASSWORD=password

# Redis
REDIS_URL=redis://localhost:6379/0

# Email
SMTP_HOST=smtp.example.com
SMTP_USERNAME=username
SMTP_PASSWORD=password

# Application
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key
```

## 🔧 Configuration

### Email Setup
Configure SMTP settings in `config/environments/production.rb`:

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_HOST'],
  port: 587,
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

### File Storage
For production, configure cloud storage in `config/storage.yml`:

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: <%= ENV['AWS_REGION'] %>
  bucket: <%= ENV['AWS_BUCKET'] %>
```

### Background Jobs
Configure Sidekiq with Redis:

```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end
```

## 📝 API Documentation

### Authentication Endpoints
- `POST /sign_in` - User authentication
- `POST /sign_up` - User registration
- `DELETE /sign_out` - User logout

### Missionary Endpoints
- `GET /missionaries` - List approved missionaries
- `GET /missionaries/:id` - Missionary profile details
- `POST /missionaries/:id/follow` - Follow missionary
- `DELETE /missionaries/:id/unfollow` - Unfollow missionary

### API Endpoints
- `GET /api/v1/missionaries` - JSON list of missionaries
- `GET /api/v1/stats` - Platform statistics
- `GET /api/v1/updates` - Recent updates feed

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Code Style
- Follow Rails conventions and best practices
- Use Rubocop for code formatting
- Write tests for all new features
- Update documentation for API changes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- **Email**: support@missionaryplatform.com
- **Documentation**: Check the `/docs` directory
- **Issues**: Use GitHub Issues for bug reports
- **Discussions**: Use GitHub Discussions for questions

## 🙏 Acknowledgments

- Built with [Ruby on Rails 8](https://rubyonrails.org/)
- Styled with [Tailwind CSS](https://tailwindcss.com/)
- Icons from [Heroicons](https://heroicons.com/)
- Background jobs with [Sidekiq](https://github.com/mperham/sidekiq)
- Testing with [RSpec](https://rspec.info/)

---

**Connecting missionaries with supporters worldwide through technology and faith.**
