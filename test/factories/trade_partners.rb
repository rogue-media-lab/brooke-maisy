FactoryBot.define do
  factory :trade_partner do
    name { "MyString" }
    trade_type { "MyString" }
    phone { "MyString" }
    email { "MyString" }
    website { "MyString" }
    description { "MyText" }
    years_experience { 1 }
    rating { "9.99" }
    jobs_referred { 1 }
    active { false }
    display_order { 1 }
  end
end
