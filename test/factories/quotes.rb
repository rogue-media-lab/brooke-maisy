FactoryBot.define do
  factory :quote do
    project { nil }
    client { nil }
    promo_code { nil }
    status { 1 }
    version_number { 1 }
    subtotal { "9.99" }
    quote_discount_type { "MyString" }
    quote_discount_value { "9.99" }
    quote_discount_reason { "MyString" }
    adjusted_subtotal { "9.99" }
    tax_rate { "9.99" }
    tax_amount { "9.99" }
    grand_total { "9.99" }
    deposit_percentage { "9.99" }
    deposit_amount { "9.99" }
    balance_due { "9.99" }
    valid_until { "2026-07-17" }
    notes { "MyText" }
    sent_at { "2026-07-17 13:53:16" }
    approved_at { "2026-07-17 13:53:16" }
  end
end
