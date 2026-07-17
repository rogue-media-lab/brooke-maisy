class Quote < ApplicationRecord
  belongs_to :project
  belongs_to :client, class_name: "User"
  belongs_to :promo_code, optional: true
  has_many :quote_line_items, dependent: :destroy
  has_many :quote_revisions, dependent: :destroy
  has_many :purchase_orders, dependent: :nullify

  validates :status, presence: true
  validates :version_number, presence: true

  enum :status, {
    draft: 0,
    sent: 1,
    viewed: 2,
    approved: 3,
    declined: 4,
    ordered: 5
  }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_client, ->(client_id) { where(client_id: client_id) }
  scope :templates, -> { where(is_template: true) }
  scope :live, -> { where(is_template: false) }
  scope :client_visible, -> { where.not(status: [ :draft ]) }
end
