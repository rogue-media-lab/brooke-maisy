FactoryBot.define do
  factory :product do
    manufacturer { nil }
    product_category { nil }
    name { "MyString" }
    description { "MyText" }
    product_url { "MyString" }
    unit { "MyString" }
    specs { "" }
    pricing { "" }
    images { "" }
    videos { "" }
    documents { "" }
    lead_time_days { 1 }
    is_active { false }
    tier { 1 }
    notes { "MyText" }
  end
end
