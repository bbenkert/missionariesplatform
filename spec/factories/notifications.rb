FactoryBot.define do
  factory :notification do
    user { nil }
    notification_type { "MyString" }
    payload { "" }
    read_at { "2025-09-02 09:15:05" }
  end
end
