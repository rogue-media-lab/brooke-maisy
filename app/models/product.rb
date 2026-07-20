class Product < ApplicationRecord
  belongs_to :manufacturer
  belongs_to :product_category
  has_many :product_swatches, dependent: :destroy
  has_many :swatches, through: :product_swatches

  validates :name, presence: true

  enum :tier, { easy_in: 1, research: 2, bulk_import: 3 }, prefix: true, validate: false

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:name) }
  scope :by_manufacturer, ->(manufacturer_id) { where(manufacturer_id: manufacturer_id) }
  scope :by_category, ->(category_id) { where(product_category_id: category_id) }
end
