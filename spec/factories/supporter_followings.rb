FactoryBot.define do
  factory :supporter_following do
    supporter { association :user, :supporter }
    missionary { association :user, :missionary }

    trait :active do
      active { true }
    end

    trait :inactive do
      active { false }
    end
  end
end
