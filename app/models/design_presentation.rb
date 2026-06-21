class DesignPresentation < ApplicationRecord
  belongs_to :project
  has_many :mood_boards, dependent: :destroy
  has_many :product_selections, dependent: :destroy
  has_many :color_swatches, dependent: :destroy

  enum :status, { draft: "draft", published: "published", archived: "archived" }, default: "draft"

  validates :title, presence: true
  validates :status, presence: true
  validates :position, presence: true

  scope :ordered, -> { order(:position, :created_at) }
  scope :published, -> { where(status: "published") }
end
