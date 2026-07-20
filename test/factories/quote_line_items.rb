FactoryBot.define do
  factory :quote_line_item do
    quote { nil }
    product { nil }
    window { nil }
    swatch { nil }
    description { "MyString" }
    width { "9.99" }
    height { "9.99" }
    quantity { 1 }
    selected_options { "" }
    unit_cost { "9.99" }
    unit_price { "9.99" }
    discount_type { "MyString" }
    discount_value { "9.99" }
    discount_reason { "MyString" }
    line_total { "9.99" }
    status { 1 }
    position { 1 }
    notes { "MyText" }
  end
end
