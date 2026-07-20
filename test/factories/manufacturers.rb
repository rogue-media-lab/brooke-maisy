FactoryBot.define do
  factory :manufacturer do
    name { "MyString" }
    website { "MyString" }
    trade_program_url { "MyString" }
    trade_discount { "9.99" }
    markup_override { "9.99" }
    notes { "MyText" }
  end
end
