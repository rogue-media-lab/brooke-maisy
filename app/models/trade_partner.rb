class TradePartner < ApplicationRecord
  TRADE_TYPES = %w[painter carpenter electrician plumber other].freeze

  validates :name, presence: true
  validates :trade_type, presence: true, inclusion: { in: TRADE_TYPES }
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:display_order, :name) }
  scope :by_type, ->(type) { where(trade_type: type) if type.present? }

  def trade_type_label
    trade_type.titleize
  end
end
