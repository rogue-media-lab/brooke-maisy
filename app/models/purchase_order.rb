class PurchaseOrder < ApplicationRecord
  belongs_to :manufacturer
  belongs_to :quote, optional: true
  has_many :purchase_order_line_items, dependent: :destroy
  has_many :quote_line_items, through: :purchase_order_line_items

  enum :status, {
    draft: 0,
    submitted: 1,
    confirmed: 2,
    shipped: 3,
    received: 4
  }

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_manufacturer, ->(manufacturer_id) { where(manufacturer_id: manufacturer_id) }
  scope :active, -> { where.not(status: [ :received ]) }

  def total_cost
    purchase_order_line_items.sum(:total_cost)
  end

  def item_count
    purchase_order_line_items.count
  end
end
