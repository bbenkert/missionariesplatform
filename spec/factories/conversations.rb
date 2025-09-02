FactoryBot.define do
  factory :conversation do
    sender { association :user, :supporter }
    recipient { association :user, :missionary }

    trait :with_messages do
      after(:create) do |conversation|
        create(:message, conversation: conversation, sender: conversation.sender)
        create(:message, conversation: conversation, sender: conversation.recipient)
      end
    end
  end
end
