class Manufacturer < ApplicationRecord
  has_many :products, dependent: :restrict_with_error
  has_many :swatches, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp, allow_blank: true }

  scope :ordered, -> { order(:name) }
end
