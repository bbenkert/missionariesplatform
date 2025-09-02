FactoryBot.define do
  factory :follow do
    association :user, factory: :user, role: :supporter
    association :followable, factory: :missionary_profile
    notifications_enabled { true }

    trait :missionary_follow do
      association :followable, factory: :missionary_profile
    end

    trait :organization_follow do
      association :followable, factory: :organization
    end

    trait :no_notifications do
      notifications_enabled { false }
    end
  end
end
