FactoryBot.define do
  factory :purchase_order_line_item do
    purchase_order { nil }
    quote_line_item { nil }
    product { nil }
    quantity { 1 }
    unit_cost { "9.99" }
    total_cost { "9.99" }
    manufacturer_sku { "MyString" }
    status { 1 }
  end
end
