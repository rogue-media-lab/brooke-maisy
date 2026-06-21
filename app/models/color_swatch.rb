class ColorSwatch < ApplicationRecord
  belongs_to :design_presentation

  HEX_CODE_REGEX = /\A#([0-9A-Fa-f]{6})\z/.freeze

  validates :name, presence: true
  validates :hex_code, presence: true, format: { with: HEX_CODE_REGEX, message: "must be a valid 6-digit hex code (e.g. #B5A397)" }
  validates :position, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
