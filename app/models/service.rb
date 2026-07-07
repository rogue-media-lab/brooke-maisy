class Service < ApplicationRecord
  validates :title, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:display_order, :title) }

  def bullet_list
    return [] if bullet_points.blank?

    bullet_points.split("\n").map(&:strip).reject(&:blank?)
  end

  def bullet_list=(lines)
    self.bullet_points = Array(lines).reject(&:blank?).join("\n")
  end
end
