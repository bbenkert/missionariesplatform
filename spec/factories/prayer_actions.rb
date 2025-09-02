FactoryBot.define do
  factory :prayer_action do
    association :user, factory: :user, role: :supporter
    association :prayer_request
    created_at { Time.current }
  end
end
