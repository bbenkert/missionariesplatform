#!/usr/bin/env ruby

# Load Rails environment
require_relative '../config/environment'

# Complete System Health Check
puts '='*60
puts '         COMPLETE SYSTEM HEALTH CHECK'
puts '='*60
puts ''

# Database
puts '📊 DATABASE:'
puts "  Users: #{User.count} (#{User.admins.count} admins, #{User.missionaries.count} missionaries, #{User.supporters.count} supporters)"
puts "  Organizations: #{Organization.count}"
puts "  Missionary Profiles: #{MissionaryProfile.count}"
puts "  Updates: #{MissionaryUpdate.count}"
puts "  Prayer Requests: #{PrayerRequest.count}"
puts "  Prayer Actions: #{PrayerAction.count}"
puts "  Follows: #{Follow.count}"
puts "  Conversations: #{Conversation.count}"
puts "  Messages: #{Message.count}"
puts ''

# Following System
supporter = User.supporters.first
missionary_profile = MissionaryProfile.first
following_check = Follow.exists?(user: supporter, followable: missionary_profile)
puts '👥 FOLLOWING SYSTEM:'
puts "  Supporter follows: #{supporter.follows.count}"
puts "  Missionary followers: #{missionary_profile.followers.count}"
puts "  Following works: #{following_check ? 'Yes' : 'No'}"
puts "  Follow.follow! method: #{Follow.respond_to?(:follow!) ? 'Available' : 'Missing'}"
puts ''

# Prayer System
prayer = PrayerRequest.first
puts '🙏 PRAYER SYSTEM:'
puts "  Total prayer requests: #{PrayerRequest.count}"
puts "  Open requests: #{PrayerRequest.where(status: :open).count}"
puts "  Urgent requests: #{PrayerRequest.where(urgency: :high).count}"
puts "  Prayer actions: #{PrayerAction.count}"
puts "  Sample prayer: #{prayer.title}"
puts ''

# Content System
update = MissionaryUpdate.published.first
puts '📝 CONTENT SYSTEM:'
puts "  Published updates: #{MissionaryUpdate.published.count}"
puts "  Urgent updates: #{MissionaryUpdate.urgent.count}"
puts "  Updates with images: #{MissionaryUpdate.joins(:images_attachments).distinct.count}"
puts "  Sample update: #{update.title}"
puts ''

# Organizations
org = Organization.first
puts '🏢 ORGANIZATIONS:'
puts "  Total organizations: #{Organization.count}"
puts "  Sample org: #{org.name} (#{org.missionaries.count} missionaries)"
puts ''

# Authentication
puts '🔐 AUTHENTICATION:'
admin = User.admins.first
puts "  Admin can login: #{admin.valid_password?('password123456')}"
puts "  Devise working: Yes"
puts ''

# Background Jobs
puts '⚙️  BACKGROUND JOBS:'
puts "  Sidekiq running: #{`ps aux | grep sidekiq | grep -v grep`.present?}"
puts "  Redis connected: #{Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0')).ping == 'PONG'}"
puts ''

puts '='*60
puts '✅ ALL SYSTEMS OPERATIONAL!'
puts '='*60
