class QuoteLineItem < ApplicationRecord
  belongs_to :quote
  belongs_to :product, optional: true
  belongs_to :window, optional: true
  belongs_to :swatch, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  enum :status, {
    proposed: 0,
    approved: 1,
    declined: 2
  }, default: :proposed, prefix: true

  scope :ordered, -> { order(:position, :created_at) }
  scope :approved, -> { where(status: :approved) }
end
