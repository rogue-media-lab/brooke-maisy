FactoryBot.define do
  factory :service do
    title { "MyString" }
    description { "MyText" }
    icon_name { "MyString" }
    bullet_points { "MyText" }
    display_order { 1 }
    active { false }
  end
end
