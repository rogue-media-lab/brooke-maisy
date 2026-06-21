class MoodBoard < ApplicationRecord
  belongs_to :design_presentation
  has_many :mood_board_items, dependent: :destroy

  validates :name, presence: true
  validates :position, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
