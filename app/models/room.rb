class Room < ApplicationRecord
  belongs_to :project
  has_many :windows, dependent: :destroy
  has_many :photos, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
