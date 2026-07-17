class PromoCode < ApplicationRecord
  has_many :quotes, dependent: :nullify

  validates :code, presence: true, uniqueness: true
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed] }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(is_active: true) }
  scope :valid_now, -> { active.where("expires_at IS NULL OR expires_at >= ?", Date.current) }
end
