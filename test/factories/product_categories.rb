FactoryBot.define do
  factory :product_category do
    name { "MyString" }
    slug { "MyString" }
    parent { nil }
    spec_template { "MyString" }
    markup_override { "9.99" }
  end
end
