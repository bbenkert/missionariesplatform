# frozen_string_literal: true

# Performance monitoring and optimization configuration
# Helps identify and prevent N+1 queries and slow database operations

if defined?(ActiveSupport::Notifications)
  # Subscribe to SQL query notifications
  ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
    duration = (finish - start) * 1000 # Convert to milliseconds
    
    # Log slow queries (> 100ms)
    if duration > 100
      Rails.logger.warn("Slow Query (#{duration.round(2)}ms): #{payload[:sql]}")
    end
    
    # Track query counts per request in development
    if Rails.env.development?
      Thread.current[:query_count] ||= 0
      Thread.current[:query_count] += 1
      
      # Warn about potential N+1 queries (>50 queries in a single request)
      if Thread.current[:query_count] > 50
        Rails.logger.warn("High query count detected: #{Thread.current[:query_count]} queries")
      end
    end
  end
  
  # Reset query counter after each request
  if Rails.env.development?
    ActiveSupport::Notifications.subscribe('process_action.action_controller') do |name, start, finish, id, payload|
      Thread.current[:query_count] = 0
    end
  end
  
  # Monitor cache operations
  ActiveSupport::Notifications.subscribe('cache_read.active_support') do |name, start, finish, id, payload|
    duration = (finish - start) * 1000
    if duration > 50 # Slow cache read
      Rails.logger.debug("Slow Cache Read (#{duration.round(2)}ms): #{payload[:key]}")
    end
  end
end

# ActiveRecord query optimization helpers
module ActiveRecordOptimizations
  # Add method to check if a relation has eager loading
  def includes_values_present?
    includes_values.any?
  end
  
  # Add method to show expected query count
  def expected_query_count
    includes_values.size + 1 # Base query + includes
  end
end

ActiveRecord::Relation.include(ActiveRecordOptimizations) if defined?(ActiveRecord::Relation)

# Log queries in development for debugging
if Rails.env.development?
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::DEBUG
end

Rails.logger.info("Performance monitoring initialized")
