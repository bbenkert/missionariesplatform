FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Ministry Organization #{n}" }
    sequence(:slug) { |n| "ministry-organization-#{n}" }
    contact_email { Faker::Internet.email }
  end
end
