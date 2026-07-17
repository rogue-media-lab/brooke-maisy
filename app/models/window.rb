class Window < ApplicationRecord
  belongs_to :room
  has_one_attached :photo

  validates :name, presence: true
  validates :width, :height, numericality: { greater_than: 0 }, allow_nil: true
  validates :mount_type, inclusion: { in: %w[inside outside], allow_blank: true }

  scope :ordered, -> { order(:position, :created_at) }
end
