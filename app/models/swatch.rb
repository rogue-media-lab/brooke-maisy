class Swatch < ApplicationRecord
  belongs_to :manufacturer
  has_many :product_swatches, dependent: :destroy
  has_many :products, through: :product_swatches

  validates :name, presence: true
  validates :hex, format: { with: /\A#([0-9A-Fa-f]{6})\z/, allow_blank: true, message: "must be a valid hex color like #FF0000" }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:name) }
  scope :by_manufacturer, ->(manufacturer_id) { where(manufacturer_id: manufacturer_id) }
  scope :by_color_range, ->(range) { where(color_range: range) }
end
