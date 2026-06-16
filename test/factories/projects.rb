FactoryBot.define do
  factory :project do
    association :user
    sequence(:title) { |n| "Project #{n}" }
    description { "A lovely interior design project." }
    status { "discovery" }
    address { "100 Main St, Rock Hill, SC" }
  end
end
