FactoryBot.define do
  factory :email_log do
    user { nil }
    email_type { "MyString" }
    resend_id { "MyString" }
    sent_at { "2025-09-02 09:14:34" }
    bounced_at { "2025-09-02 09:14:34" }
    complained_at { "2025-09-02 09:14:34" }
    delivered_at { "2025-09-02 09:14:34" }
    meta { "" }
  end
end
