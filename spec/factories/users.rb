FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    is_active { true }

    trait :supporter do
      role { :supporter }
      status { :approved }
    end

    trait :missionary do
      role { :missionary }
      status { :pending }
    end

    trait :admin do
      role { :admin }
      status { :approved }
    end
    
    trait :organization_admin do
      role { :organization_admin }
      status { :approved }
    end

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
    end

    trait :flagged do
      status { :flagged }
    end

    trait :suspended do
      status { :suspended }
    end

    trait :inactive do
      is_active { false }
    end
  end
end
