FactoryBot.define do
  factory :project_update do
    association :project
    body { "Progress update on the project." }
    visible_to_client { true }
  end
end
