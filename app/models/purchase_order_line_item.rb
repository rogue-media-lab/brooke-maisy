class PurchaseOrderLineItem < ApplicationRecord
  belongs_to :purchase_order
  belongs_to :quote_line_item, optional: true
  belongs_to :product, optional: true

  enum :status, {
    pending: 0,
    ordered: 1,
    backordered: 2,
    received: 3
  }, default: :pending

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  scope :ordered, -> { order(:id) }
end
