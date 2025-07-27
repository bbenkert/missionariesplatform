# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating admin user..."
admin = User.find_or_create_by(email: "admin@missionaryplatform.com") do |user|
  user.name = "Admin User"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "admin"
  user.status = "approved"
end

puts "Creating sample supporters..."
5.times do |i|
  User.find_or_create_by(email: "supporter#{i+1}@example.com") do |user|
    user.name = "Supporter #{i+1}"
    user.password = "password123"
    user.password_confirmation = "password123"
    user.role = "supporter"
    user.status = "approved"
  end
end

puts "Creating sample missionaries..."
countries = ["Kenya", "Brazil", "Thailand", "Romania", "Mexico", "Philippines", "India", "Uganda"]
organizations = ["OMF International", "Wycliffe Bible Translators", "SIM", "Campus Crusade", "Youth With A Mission"]
ministry_focuses = ["Church Planting", "Bible Translation", "Medical Missions", "Youth Ministry", "Education", "Community Development"]

10.times do |i|
  missionary = User.find_or_create_by(email: "missionary#{i+1}@example.com") do |user|
    user.name = "Missionary #{i+1}"
    user.password = "password123"
    user.password_confirmation = "password123"
    user.role = "missionary"
    user.status = "approved"
  end

  # Only create profile if it doesn't exist
  unless missionary.missionary_profile.present?
    missionary.create_missionary_profile!(
      bio: "Dedicated missionary serving in #{countries.sample}. Passionate about #{ministry_focuses.sample.downcase} and building relationships with the local community.",
      ministry_focus: ministry_focuses.sample,
      organization: organizations.sample,
      country: countries.sample,
      city: "Sample City #{i+1}",
      prayer_requests: "Please pray for:\n- Language learning\n- Building relationships with locals\n- Wisdom in ministry decisions",
      ministry_description: "Working with local communities to share the Gospel and provide practical support where needed.",
      started_ministry_at: rand(1..10).years.ago
    )
  end
end

puts "Creating sample updates..."
User.missionaries.approved.each do |missionary|
  rand(2..5).times do
    missionary.missionary_updates.create!(
      title: Faker::Lorem.sentence(word_count: 6),
      content: Faker::Lorem.paragraphs(number: rand(2..4)).join("\n\n"),
      update_type: ['general', 'prayer_request', 'praise_report', 'ministry_news'].sample,
      status: 'published',
      is_urgent: [true, false, false, false].sample, # 25% chance of urgent
      published_at: rand(30.days).seconds.ago
    )
  end
end

puts "Creating sample followings..."
supporters = User.supporters
missionaries = User.missionaries.approved

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
  end
end

puts "Seed data created successfully!"
puts "Admin: admin@missionaryplatform.com / password123"
puts "Sample supporter: supporter1@example.com / password123"
puts "Sample missionary: missionary1@example.com / password123"
