FactoryBot.define do
  factory :missionary_update do
    user { association :user, :missionary }
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    status { :published }

    trait :published do
      status { :published }
    end

    trait :draft do
      status { :draft }
    end

    trait :archived do
      status { :archived }
    end

    trait :with_prayer_request do
      prayer_request { Faker::Lorem.paragraph }
    end

    trait :with_image do
      after(:create) do |update|
        update.image.attach(io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'update_image.jpg')), filename: 'update_image.jpg')
      end
    end
  end
end
