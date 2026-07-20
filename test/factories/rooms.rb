FactoryBot.define do
  factory :room do
    project { nil }
    name { "MyString" }
    position { 1 }
    notes { "MyText" }
  end
end
