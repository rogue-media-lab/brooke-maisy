FactoryBot.define do
  factory :window do
    room { nil }
    name { "MyString" }
    width { "9.99" }
    height { "9.99" }
    mount_type { "MyString" }
    depth { "9.99" }
    notes { "MyText" }
    position { 1 }
  end
end
