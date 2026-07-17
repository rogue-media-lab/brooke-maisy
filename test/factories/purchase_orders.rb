FactoryBot.define do
  factory :purchase_order do
    manufacturer { nil }
    quote { nil }
    status { 1 }
    order_date { "2026-07-17" }
    expected_delivery { "2026-07-17" }
    actual_delivery { "2026-07-17" }
    notes { "MyText" }
  end
end
