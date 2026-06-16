FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "client#{n}@example.com" }
    password { "Password123!" }
    role { "client" }

    trait :admin do
      role { "admin" }
    end
  end
end
