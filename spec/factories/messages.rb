FactoryBot.define do
  factory :message do
    conversation
    sender { association :user }
    content { Faker::Lorem.paragraph }

    trait :read do
      read_at { Time.current }
    end

    trait :unread do
      read_at { nil }
    end
  end
end
