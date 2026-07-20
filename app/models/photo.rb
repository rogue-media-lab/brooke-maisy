class Photo < ApplicationRecord
  belongs_to :room, optional: true
  belongs_to :window, optional: true
  belongs_to :quote, optional: true

  has_one_attached :image

  enum :kind, {
    measurement: 0,    # raw photo of the window/room during measure
    installer: 1,      # reference photo for installers
    reference: 2,      # finished room mockup (future AI generation)
    progress: 3        # during installation
  }, default: :measurement

  validates :label, presence: true
  validates :image, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
