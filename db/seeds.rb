# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating organizations..."
organizations_data = [
  { name: "OMF International", description: "Serving East Asia's peoples through church planting, medical work, and community development." },
  { name: "Wycliffe Bible Translators", description: "Working to make God's Word accessible to all people in the language of their heart." },
  { name: "SIM", description: "Serving in Africa and beyond to see thriving communities transformed by the gospel." },
  { name: "Campus Crusade for Christ", description: "Helping fulfill the Great Commission by winning, building, and sending." },
  { name: "Youth With A Mission", description: "Training and mobilizing young people for global missions." }
]

organizations = organizations_data.map do |org_data|
  Organization.find_or_create_by(name: org_data[:name]) do |org|
    org.description = org_data[:description]
    org.contact_email = "info@#{org_data[:name].parameterize}.org"
    org.settings = {
      allow_public_profiles: true,
      auto_approve_missionaries: false,
      max_prayer_requests_per_missionary: 10
    }
  end
end

puts "Creating admin user..."
admin = User.find_or_create_by(email: "admin@missionaryplatform.com") do |user|
  user.name = "Admin User"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "admin"
  user.status = "approved"
  user.organization = organizations.sample
end

puts "Creating sample supporters..."
5.times do |i|
  User.find_or_create_by(email: "supporter#{i+1}@example.com") do |user|
    user.name = "Supporter #{i+1}"
    user.password = "password123"
    user.password_confirmation = "password123"
    user.role = "supporter"
    user.status = "approved"
    user.organization = organizations.sample
  end
end

puts "Creating sample missionaries..."
countries = ["Kenya", "Brazil", "Thailand", "Romania", "Mexico", "Philippines", "India", "Uganda"]
ministry_focuses = ["Church Planting", "Bible Translation", "Medical Missions", "Youth Ministry", "Education", "Community Development"]

10.times do |i|
  missionary = User.find_or_create_by(email: "missionary#{i+1}@example.com") do |user|
    user.name = "Missionary #{i+1}"
    user.password = "password123"
    user.password_confirmation = "password123"
    user.role = "missionary"
    user.status = "approved"
    user.organization = organizations.sample
  end

  # Only create profile if it doesn't exist
  unless missionary.missionary_profile.present?
    safety_modes = [:public, :limited, :private]
    missionary.create_missionary_profile!(
      bio: "Dedicated missionary serving in #{countries.sample}. Passionate about #{ministry_focuses.sample.downcase} and building relationships with the local community.",
      ministry_focus: ministry_focuses.sample,
      organization: organizations.sample.name,
      country: countries.sample,
      city: "Sample City #{i+1}",
      prayer_requests: "Please pray for:\n- Language learning\n- Building relationships with locals\n- Wisdom in ministry decisions",
      ministry_description: "Working with local communities to share the Gospel and provide practical support where needed.",
      started_ministry_at: rand(1..10).years.ago,
      safety_mode: safety_modes.sample
    )
  end
end

puts "Creating sample updates..."
User.missionaries.approved.each do |missionary|
  rand(2..5).times do
    missionary.missionary_updates.create!(
      title: Faker::Lorem.sentence(word_count: 6),
      content: Faker::Lorem.paragraphs(number: rand(2..4)).join("\n\n"),
      update_type: ['general_update', 'prayer_request', 'praise_report', 'ministry_news'].sample,
      status: 'published',
      is_urgent: [true, false, false, false].sample, # 25% chance of urgent
      published_at: rand(30.days).seconds.ago
    )
  end
end

puts "Creating sample prayer requests..."
prayer_titles = [
  "Healing for Local Pastor",
  "Safe Travel to Remote Villages", 
  "Language Learning Progress",
  "Wisdom in Ministry Decisions",
  "Protection During Outreach",
  "Community Relationships",
  "Financial Provision",
  "Church Building Project",
  "Bible Translation Work",
  "Youth Ministry Growth"
]

prayer_tags = [
  ["healing", "health", "prayer"],
  ["travel", "safety", "protection"],
  ["language", "learning", "communication"],
  ["wisdom", "guidance", "decisions"],
  ["protection", "safety", "ministry"],
  ["relationships", "community", "fellowship"],
  ["finances", "provision", "support"],
  ["building", "construction", "church"],
  ["translation", "bible", "language"],
  ["youth", "ministry", "growth"]
]

User.missionaries.approved.each do |missionary|
  next unless missionary.missionary_profile
  
  rand(1..3).times do |i|
    title = prayer_titles.sample
    tags = prayer_tags.sample
    urgency = [:low, :medium, :high].sample
    
    prayer_request = missionary.missionary_profile.prayer_requests.create!(
      title: title,
      body: "Please join us in prayer for this important matter. #{Faker::Lorem.paragraph(sentence_count: rand(2..4))}",
      tags: tags,
      urgency: urgency,
      status: :open
    )
    
    # Some prayer requests get prayer actions from supporters
    if rand < 0.7 # 70% of prayer requests get prayers
      User.supporters.sample(rand(1..3)).each do |supporter|
        PrayerAction.pray!(user: supporter, prayer_request: prayer_request)
      rescue ActiveRecord::RecordInvalid
        # Skip if already prayed
      end
    end
  end
end

puts "Creating sample followings with new Follow model..."
supporters = User.supporters
missionaries = User.missionaries.approved
organizations = Organization.all

supporters.each do |supporter|
  # Each supporter follows 2-4 missionaries using new Follow model
  missionaries.sample(rand(2..4)).each do |missionary_user|
    if missionary_user.missionary_profile
      Follow.follow!(user: supporter, followable: missionary_user.missionary_profile)
    end
  end
  
  # Some supporters also follow organizations
  if rand < 0.5 # 50% chance to follow an organization
    organizations.sample(rand(1..2)).each do |org|
      Follow.follow!(user: supporter, followable: org)
    end
  end
end

# Legacy followings for backward compatibility
supporters.each do |supporter|
  # Each supporter follows 2-4 missionaries
  missionaries.sample(rand(2..4)).each do |missionary|
    begin
      supporter.supporter_followings.create!(
        missionary: missionary,
        email_notifications: [true, false].sample
      )
    rescue ActiveRecord::RecordInvalid
      # Skip if already following
    end
  end
end

puts "Creating sample conversations and messages..."
supporters.limit(3).each do |supporter|
  missionaries.limit(2).each do |missionary|
    begin
      conversation = Conversation.create!(
        sender: supporter,
        recipient: missionary
      )
      
      # Add some messages to the conversation
      rand(2..5).times do |i|
        sender = [supporter, missionary].sample
        Message.create!(
          conversation: conversation,
          sender: sender,
          content: Faker::Lorem.paragraph(sentence_count: rand(2..4)),
          read_at: i == 0 ? nil : rand(7.days).seconds.ago # First message unread
        )
      end
    rescue ActiveRecord::RecordInvalid => e
      # Skip if conversation already exists
      puts "Skipping conversation: #{e.message}"
    end
  end
end

puts "Seed data created successfully!"
puts ""
puts "=== Login Credentials ==="
puts "Admin: admin@missionaryplatform.com / password123"
puts "Sample supporter: supporter1@example.com / password123"
puts "Sample missionary: missionary1@example.com / password123"
puts ""
puts "=== Statistics ==="
puts "Organizations: #{Organization.count}"
puts "Users: #{User.count}"
puts "- Admins: #{User.admins.count}"
puts "- Missionaries: #{User.missionaries.count}"
puts "- Supporters: #{User.supporters.count}"
puts "Missionary Profiles: #{MissionaryProfile.count}"
puts "Prayer Requests: #{PrayerRequest.count}"
puts "Prayer Actions: #{PrayerAction.count}"
puts "Follows: #{Follow.count}"
puts "Updates: #{MissionaryUpdate.count}"
puts "Conversations: #{Conversation.count}"
puts "Messages: #{Message.count}"
