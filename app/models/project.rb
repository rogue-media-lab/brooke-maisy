class Project < ApplicationRecord
  belongs_to :user
  has_many :project_updates, dependent: :destroy
  has_many_attached :photos

  enum :status, {
    discovery: "discovery",
    design: "design",
    in_progress: "in_progress",
    complete: "complete"
  }, default: "discovery"

  validates :title, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
