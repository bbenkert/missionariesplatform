FactoryBot.define do
  factory :missionary_profile do
    user
    association :organization
    ministry_focus { "Evangelism" }
    bio { "A simple bio." }
    country { "USA" }
    city { "New York" }
    giving_links { [].to_json } # Empty array for now

    # Remove traits for now to simplify
    # trait :with_website do
    #   website { "http://example.com" }
    # end

    # trait :with_social_links do
    #   facebook_url { "http://facebook.com/profile" }
    #   twitter_url { "http://twitter.com/profile" }
    #   instagram_url { "http://instagram.com/profile" }
    # end
  end
end