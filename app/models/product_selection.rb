class ProductSelection < ApplicationRecord
  belongs_to :design_presentation
  has_one_attached :image

  enum :status, { proposed: "proposed", approved: "approved", rejected: "rejected" }, default: "proposed"

  validates :name, presence: true
  validates :status, presence: true
  validates :position, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
