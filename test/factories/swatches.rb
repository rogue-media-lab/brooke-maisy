FactoryBot.define do
  factory :swatch do
    manufacturer { nil }
    name { "MyString" }
    hex { "MyString" }
    category { "MyString" }
    color_range { "MyString" }
    image_url { "MyString" }
    is_new { false }
    is_active { false }
  end
end
