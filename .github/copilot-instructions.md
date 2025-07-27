<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Missionary Platform - Rails 8 Development Guidelines

## Project Overview
This is a Ruby on Rails 8 application for connecting missionaries with supporters worldwide. The platform features multi-role authentication, profile management, messaging, and email notifications.

## Code Style & Conventions

### Rails Best Practices
- Follow Rails 8 conventions and modern patterns
- Use Strong Parameters for form handling
- Leverage Rails' built-in security features (CSRF, etc.)
- Implement proper error handling and user feedback
- Use Rails' built-in authentication patterns with secure sessions

### Model Guidelines
- Use ActiveRecord associations and validations
- Implement proper scopes and class methods
- Follow the Single Responsibility Principle
- Include proper error handling and edge cases
- Use concerns for shared functionality

### Controller Guidelines
- Keep controllers thin, move logic to models or services
- Use before_actions for authentication and authorization
- Implement proper error handling with user-friendly messages
- Use Hotwire/Turbo for dynamic interactions
- Follow RESTful conventions

### View Guidelines  
- Use Tailwind CSS classes for styling
- Implement responsive design patterns
- Use Rails helpers and partials for reusability
- Follow accessibility best practices
- Implement proper error display and user feedback

### Security Considerations
- Always use Strong Parameters
- Implement proper authorization checks
- Validate user input thoroughly
- Use Rails' built-in CSRF protection
- Implement rate limiting for sensitive actions

## Architecture Patterns

### User Roles
- **Admin**: Full platform management, user approval, content moderation
- **Missionary**: Profile management, posting updates, messaging
- **Supporter**: Following missionaries, receiving updates, messaging

### Key Models
- `User`: Authentication and role management
- `MissionaryProfile`: Extended missionary information
- `MissionaryUpdate`: Posts and prayer requests
- `SupporterFollowing`: Follower relationships
- `Conversation` & `Message`: Private messaging system

### Background Jobs
- Use Sidekiq for email notifications and digest processing
- Implement proper error handling and retry logic
- Keep jobs idempotent and well-documented

## Testing Guidelines
- Write comprehensive RSpec tests for all models and controllers
- Use FactoryBot for test data creation
- Implement system tests for critical user workflows
- Test authentication and authorization thoroughly
- Mock external services and email delivery

## Email & Notifications
- Use ActionMailer with background job delivery
- Implement user preferences for email frequency
- Create responsive email templates
- Handle email delivery failures gracefully

## Database Guidelines
- Use proper indexing for performance
- Implement database constraints where appropriate
- Use migrations for all schema changes
- Follow Rails naming conventions
- Consider database performance for queries

## Performance Considerations
- Use eager loading to avoid N+1 queries
- Implement caching for expensive operations
- Optimize database queries and indexes
- Use pagination for large datasets
- Monitor and optimize background job performance

## Deployment & Operations
- Use Docker for consistent development environments
- Implement proper logging and monitoring
- Use environment variables for configuration
- Implement health checks and status endpoints
- Consider scaling for background job processing

When generating code for this project, please:
1. Follow Rails 8 conventions and best practices
2. Use Tailwind CSS for styling with the existing design system
3. Implement proper error handling and user feedback
4. Include appropriate tests for new functionality
5. Consider security implications and implement proper authorization
6. Use the existing model associations and patterns
7. Follow the established architectural patterns and code organization
