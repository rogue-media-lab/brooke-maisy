class ProductCategory < ApplicationRecord
  belongs_to :parent, class_name: "ProductCategory", optional: true
  has_many :children, class_name: "ProductCategory", foreign_key: :parent_id, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :parent_id }
  validates :slug, presence: true, uniqueness: true

  scope :top_level, -> { where(parent_id: nil).ordered }
  scope :ordered, -> { order(:name) }
end
