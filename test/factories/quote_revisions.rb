FactoryBot.define do
  factory :quote_revision do
    quote { nil }
    version_number { 1 }
    snapshot { "" }
  end
end
