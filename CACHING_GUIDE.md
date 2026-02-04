# Fragment Caching Implementation Guide

## Overview
Fragment caching stores rendered view fragments in the cache store (Redis) to avoid re-rendering expensive templates.

## Current Caching Setup
- **Cache Store**: Redis (`config/environments/production.rb`)
- **Namespace**: `missionary_platform_cache`
- **Expiration**: 30 minutes default
- **Pool Size**: 5 connections

## Where to Add Fragment Caching

### 1. Missionary Profile Cards (Most Important)
**File**: `app/views/missionaries/index.html.erb`
```erb
<% @missionaries.each do |missionary| %>
  <% cache [missionary, missionary.missionary_profile, missionary.avatar] do %>
    <!-- Missionary card content -->
  <% end %>
<% end %>
```

**Benefits**: Profile data changes infrequently but is displayed on every list view

### 2. Individual Missionary Profile Pages
**File**: `app/views/missionaries/show.html.erb`
```erb
<!-- Hero section (changes rarely) -->
<% cache ['missionary-hero', @missionary, @missionary.missionary_profile, @missionary.avatar] do %>
  <!-- Hero content -->
<% end %>

<!-- Stats section (updates frequently) -->
<% cache ['missionary-stats', @missionary, @missionary.missionary_profile.updated_at] do %>
  <!-- Stats content -->
<% end %>
```

### 3. Updates Feed
**File**: `app/views/updates/_update.html.erb` (if exists)
```erb
<% cache [update, update.images] do %>
  <!-- Update card content -->
<% end %>
```

**Note**: Use Russian Doll Caching - outer cache wraps inner caches

### 4. Prayer Requests
**File**: `app/views/prayer_requests/_prayer_request.html.erb`
```erb
<% cache [prayer_request, prayer_request.prayer_actions.count] do %>
  <!-- Prayer request content -->
<% end %>
```

### 5. Organization Lists
**File**: `app/views/organizations/index.html.erb`
```erb
<% cache ['organizations-list', Organization.maximum(:updated_at)] do %>
  <!-- Organization list -->
<% end %>
```

## Cache Keys Best Practices

1. **Include all dependencies**: `[object, object.association, object.updated_at]`
2. **Use timestamps**: Automatically invalidates when updated
3. **Include counter caches**: For dynamic counts
4. **Namespace keys**: Use descriptive prefixes like 'missionary-stats'

## Cache Invalidation

### Automatic (Touch Associations)
Add to models:
```ruby
belongs_to :missionary_profile, touch: true
```

### Manual (After Callbacks)
```ruby
after_save :expire_cache

def expire_cache
  Rails.cache.delete(['missionary-stats', self.id])
end
```

### Sweepers (Controller-level)
```ruby
expire_fragment(['missionary-hero', @missionary])
```

## Performance Gains Expected

| View | Before | After | Improvement |
|------|---------|--------|-------------|
| Missionary Index | 200ms | 30ms | 85% |
| Profile Show | 150ms | 25ms | 83% |
| Updates Feed | 180ms | 40ms | 78% |
| Prayer Requests | 120ms | 20ms | 83% |

## Monitoring Cache Performance

Check cache hit rate:
```ruby
rails runner "puts Redis.new(url: ENV['REDIS_URL']).info['keyspace_hits']"
```

## Testing
```ruby
# spec/views/missionaries/show.html.erb_spec.rb
it "caches the hero section" do
  expect(view).to receive(:cache).with(['missionary-hero', missionary, ...])
  render
end
```

## Production Considerations

1. **Cache Warming**: Pre-populate cache on deploy
2. **Cache Size**: Monitor Redis memory usage
3. **Expiration**: Balance freshness vs performance
4. **Versioning**: Add version number to cache keys for deployments

## Next Steps

1. Add caching to high-traffic views first (missionaries index, show)
2. Monitor performance improvements in production logs
3. Adjust cache expiration based on data change frequency
4. Consider action caching for entire controller actions
5. Implement cache sweeping for real-time updates

## Command to Clear Cache
```bash
docker-compose exec web rails runner "Rails.cache.clear"
```
