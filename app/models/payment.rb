class Payment < ApplicationRecord
  belongs_to :quote

  enum :method, {
    square_terminal: 0,
    check: 1,
    cash: 2,
    bank_transfer: 3,
    other: 4
  }, default: :square_terminal

  enum :kind, {
    deposit: 0,
    balance: 1,
    partial: 2
  }, default: :deposit

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_at, presence: true
  validates :method, presence: true
  validates :kind, presence: true

  scope :ordered, -> { order(:paid_at, :created_at) }
end
