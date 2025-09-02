FactoryBot.define do
  factory :prayer_request do
    association :missionary_profile
    title { Faker::Lorem.sentence(word_count: 4).chomp('.') }
    body { Faker::Lorem.paragraph(sentence_count: 3) }
    tags { ['healing', 'family', 'ministry'].sample(2) }
    status { :open }
    urgency { :medium }
    published_at { Time.current }

    trait :draft do
      status { :draft }
      published_at { nil }
    end

    trait :urgent do
      urgency { :high }
    end

    trait :archived do
      status { :closed }
    end

    trait :with_tags do
      tags { ['healing', 'travel', 'family', 'ministry', 'health'] }
    end
  end
end
