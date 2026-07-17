class ProductSwatch < ApplicationRecord
  belongs_to :product
  belongs_to :swatch

  validates :product_id, uniqueness: { scope: :swatch_id }
end
