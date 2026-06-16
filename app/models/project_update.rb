class ProjectUpdate < ApplicationRecord
  belongs_to :project

  validates :body, presence: true

  scope :client_visible, -> { where(visible_to_client: true) }
  scope :recent, -> { order(created_at: :desc) }
end
