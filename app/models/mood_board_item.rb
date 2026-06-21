class MoodBoardItem < ApplicationRecord
  belongs_to :mood_board
  has_one_attached :image

  validates :position, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
