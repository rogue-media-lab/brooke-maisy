class Client < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :purchase_orders, dependent: :nullify
  has_one :user, dependent: :restrict_with_error

  validates :name, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :alphabetical, -> { order(:name) }

  def display_name
    name
  end

  def first_name
    name.split.first
  end

  def portal_enabled?
    user.present?
  end
end
