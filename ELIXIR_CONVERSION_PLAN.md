# Rails to Elixir/Phoenix/Ash Conversion Plan

## Executive Summary

This document outlines a comprehensive plan to convert the Rails 8 missionary platform to Elixir/Phoenix with Ash Framework. The current Rails application is a complex multi-role platform connecting missionaries with supporters worldwide, featuring rich content, messaging, prayer requests, and organization management.

## Current Rails Application Analysis

### Core Features
- **Multi-role Authentication**: Admin, Missionary, Supporter, Organization Admin roles
- **Rich Content System**: ActionText for updates, prayer requests with formatting
- **File Management**: ActiveStorage for avatars, banners, and update images
- **Messaging System**: Private conversations between supporters and missionaries
- **Following System**: Polymorphic follows for missionaries and organizations
- **Prayer Requests**: Trackable prayer commitments with urgency levels
- **Safety Modes**: Public/Limited/Private visibility controls for missionaries
- **Email Notifications**: Weekly digests, urgent prayers, new updates
- **Organization Management**: Group missionaries under organizations
- **Background Processing**: Sidekiq jobs for email delivery and digests

### Database Schema (15+ tables)
- `users` - Authentication and roles
- `missionary_profiles` - Extended missionary information
- `missionary_updates` - Rich text content posts
- `prayer_requests` - Prayer needs with tracking
- `conversations` & `messages` - Private messaging
- `follows` - Polymorphic following relationships
- `organizations` - Group management
- `notifications` & `email_logs` - Notification system
- `prayer_actions` - Prayer commitment tracking

### Technology Stack
- Rails 8 with modern features (Turbo, Stimulus, Propshaft)
- PostgreSQL with full-text search
- Devise authentication with Pundit authorization
- Sidekiq background processing
- Resend email service
- Tailwind CSS styling

## Conversion Strategy

### Phase 1: Foundation Setup (Week 1-2)

#### 1.1 Project Initialization
- Create new Phoenix project with Ash Framework
- Set up PostgreSQL database with proper extensions
- Configure Ash Framework with authentication
- Initialize LiveView for interactive UI
- Set up Tailwind CSS with Phoenix integration

#### 1.2 Core Dependencies Setup
```elixir
# mix.exs dependencies
{:ash, "~> 3.0"},
{:ash_phoenix, "~> 2.0"},
{:ash_authentication, "~> 4.0"},
{:ash_authentication_phoenix, "~> 2.0"},
{:phoenix_live_view, "~> 1.0"},
{:tailwind, "~> 0.2"},
{:oban, "~> 2.17"}, # Background jobs
{:resend, "~> 0.4"}, # Email service
{:waffle, "~> 1.1"}, # File uploads
{:waffle_ecto, "~> 0.0"},
```

#### 1.3 Database Migration Strategy
- Convert Rails migrations to Ecto migrations
- Implement full-text search with PostgreSQL tsvector
- Set up proper indexes and constraints
- Handle polymorphic relationships in Ash

### Phase 2: Authentication & User Management (Week 3-4)

#### 2.1 Ash Authentication Setup
```elixir
# User resource with Ash Authentication
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    domain: MyApp.Accounts,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :email, :string, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :role, :atom do
      constraints one_of: [:supporter, :missionary, :admin, :organization_admin]
      default :supporter
    end
    attribute :status, :atom do
      constraints one_of: [:pending, :approved, :flagged, :suspended]
      default :pending
    end
    # ... additional attributes
  end

  authentication do
    strategies do
      password :password do
        identity_field :email
        hashed_password_field :hashed_password
      end
    end
  end

  # Relationships and validations...
end
```

#### 2.2 Role-Based Authorization
- Implement Ash authorization policies
- Convert Pundit policies to Ash policies
- Set up proper permission boundaries
- Handle admin/organization admin special cases

#### 2.3 User Registration Flow
- Multi-step registration with role selection
- Organization assignment for missionaries
- Email verification workflow
- Approval workflow for missionaries

### Phase 3: Core Domain Models (Week 5-7)

#### 3.1 Missionary Profile System
```elixir
defmodule MyApp.Missionary.Profile do
  use Ash.Resource

  attributes do
    attribute :bio, :string
    attribute :ministry_focus, :string, allow_nil?: false
    attribute :country, :string, allow_nil?: false
    attribute :city, :string
    attribute :safety_mode, :atom do
      constraints one_of: [:public_mode, :limited_mode, :private_mode]
      default :public_mode
    end
    attribute :giving_links, {:array, :string}
  end

  relationships do
    belongs_to :user, MyApp.Accounts.User, allow_nil?: false
    belongs_to :organization, MyApp.Organizations.Organization
    has_many :prayer_requests, MyApp.Prayer.Request
    many_to_many :followers, MyApp.Accounts.User do
      through MyApp.Follows.Follow
      source_attribute_on_join_resource :followable_id
      destination_attribute_on_join_resource :user_id
    end
  end

  # Policies for safety mode visibility
  policies do
    policy action_type(:read) do
      authorize_if expr(safety_mode == :public_mode)
      authorize_if expr(safety_mode == :limited_mode and user_role == :supporter)
      authorize_if expr(user_id == ^actor(:id) or user_role == :admin)
    end
  end
end
```

#### 3.2 Content Management (Updates & Prayer Requests)
- Convert ActionText rich content to custom rich text implementation
- Implement file upload system with Waffle
- Set up content moderation and approval workflows
- Handle content visibility and safety modes

#### 3.3 Messaging System
```elixir
defmodule MyApp.Messaging.Conversation do
  use Ash.Resource

  relationships do
    belongs_to :sender, MyApp.Accounts.User, allow_nil?: false
    belongs_to :recipient, MyApp.Accounts.User, allow_nil?: false
    has_many :messages, MyApp.Messaging.Message
  end

  validations do
    validate {MyApp.Messaging.Validations.CanMessage,
              attribute: :recipient_id, actor: :sender}
  end
end
```

### Phase 4: Advanced Features (Week 8-10)

#### 4.1 Following & Social Features
- Implement polymorphic following with Ash unions
- Handle notification preferences
- Set up follower counts and analytics
- Implement unfollow/follow actions

#### 4.2 Prayer Tracking System
```elixir
defmodule MyApp.Prayer.Action do
  use Ash.Resource

  relationships do
    belongs_to :user, MyApp.Accounts.User, allow_nil?: false
    belongs_to :prayer_request, MyApp.Prayer.Request, allow_nil?: false
  end

  # Ensure idempotent prayer actions
  identities do
    identity :unique_prayer, [:user_id, :prayer_request_id]
  end
end
```

#### 4.3 Organization Management
- Organization hierarchy and permissions
- Organization admin dashboards
- Bulk operations for organization members
- Organization-level analytics

### Phase 5: Background Processing & Email (Week 11-12)

#### 5.1 Oban Job Setup
```elixir
defmodule MyApp.Workers.WeeklyDigest do
  use Oban.Worker, queue: :email

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    user = MyApp.Accounts.get_user!(user_id)
    MyApp.Email.send_weekly_digest(user)
  end
end
```

#### 5.2 Email Service Integration
- Convert Resend integration from Rails
- Implement email templates with Phoenix
- Handle email preferences and unsubscribes
- Set up email delivery tracking

### Phase 6: Frontend & UI (Week 13-15)

#### 6.1 LiveView Implementation
- Convert Turbo/Stimulus interactions to LiveView
- Implement real-time messaging with LiveView
- Set up notification system with LiveView
- Handle file uploads with LiveView

#### 6.2 Responsive Design
- Convert Tailwind CSS classes
- Implement mobile-first responsive design
- Set up proper accessibility features
- Optimize for performance

### Phase 7: Testing & Deployment (Week 16-17)

#### 7.1 Testing Strategy
- Unit tests for Ash resources
- Integration tests for LiveView components
- Email delivery testing
- Background job testing

#### 7.2 Deployment Setup
- Docker containerization
- Database migration handling
- Environment configuration
- Monitoring and logging setup

## Technical Challenges & Solutions

### 1. Polymorphic Relationships
**Challenge**: Rails polymorphic associations vs Ash relationships
**Solution**: Use Ash unions and discriminated unions for flexible relationships

### 2. Rich Text Content
**Challenge**: ActionText vs Phoenix rich text
**Solution**: Implement custom rich text with Tiptap.js and store as JSON

### 3. File Uploads
**Challenge**: ActiveStorage vs Phoenix file handling
**Solution**: Use Waffle with Arc for flexible file storage

### 4. Real-time Features
**Challenge**: ActionCable vs Phoenix channels
**Solution**: Leverage Phoenix Channels for real-time messaging and notifications

### 5. Authorization Complexity
**Challenge**: Pundit policies vs Ash authorization
**Solution**: Convert to declarative Ash policies with proper actor context

## Migration Strategy

### Data Migration Plan
1. Export Rails data to JSON/CSV
2. Create Ecto migration scripts
3. Handle ID mapping between systems
4. Validate data integrity post-migration

### User Communication
1. Notify users of platform migration
2. Provide migration timeline
3. Offer support during transition
4. Handle account linking for existing users

## Success Metrics

### Technical Metrics
- 100% feature parity with Rails application
- Response times < 200ms for API endpoints
- 99.9% uptime for production deployment
- Zero data loss during migration

### Business Metrics
- Maintain user engagement levels
- Preserve conversion rates
- Improve email deliverability
- Enhance mobile experience

## Risk Mitigation

### Technical Risks
- Complex polymorphic relationship conversion
- Rich text content migration challenges
- Real-time feature implementation complexity

### Business Risks
- User experience disruption during migration
- Feature gaps causing user churn
- Extended timeline impacting budget

### Mitigation Strategies
- Incremental feature rollout
- Comprehensive testing before deployment
- User feedback loops during development
- Rollback plan for critical issues

## Timeline & Milestones

- **Week 1-2**: Foundation setup and basic authentication
- **Week 3-4**: User management and role-based access
- **Week 5-7**: Core domain models (profiles, updates, prayers)
- **Week 8-10**: Advanced features (messaging, following, organizations)
- **Week 11-12**: Background jobs and email system
- **Week 13-15**: Frontend implementation with LiveView
- **Week 16-17**: Testing, deployment, and data migration

## Team Requirements

### Skills Needed
- Senior Elixir/Phoenix developer
- Ash Framework expertise
- PostgreSQL database design
- LiveView development experience
- Email system integration
- Docker deployment experience

### Development Environment
- Elixir 1.16+
- Phoenix 1.7+
- Ash Framework 3.0+
- PostgreSQL 15+
- Node.js for asset compilation

This conversion plan provides a structured approach to migrating from Rails to Elixir/Phoenix while maintaining all existing functionality and improving performance and maintainability.