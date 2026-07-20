FactoryBot.define do
  factory :promo_code do
    code { "MyString" }
    discount_type { "MyString" }
    discount_value { "9.99" }
    min_purchase { "9.99" }
    expires_at { "2026-07-17" }
    usage_limit { 1 }
    usage_count { 1 }
    is_active { false }
  end
end
