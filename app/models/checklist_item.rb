class ChecklistItem < ApplicationRecord
  validates :name, presence: true

  scope :active, -> { where(active: true).order(:position) }
  scope :ordered, -> { order(:position) }
end