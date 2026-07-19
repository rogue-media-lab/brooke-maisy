class Quote < ApplicationRecord
  belongs_to :client
  belongs_to :project, optional: true
  belongs_to :promo_code, optional: true
  has_many :quote_line_items, dependent: :destroy
  has_many :quote_revisions, dependent: :destroy
  has_many :purchase_orders, dependent: :nullify
  has_many :photos, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :signatures, dependent: :destroy

  validates :status, presence: true
  validates :version_number, presence: true
  validates :valid_until, presence: true

  enum :status, {
    draft: 0,
    sent: 1,
    viewed: 2,
    approved: 3,
    declined: 4,
    ordered: 5
  }

  enum :workflow_stage, {
    client_info: 0,      # Stage 1: Measure
    measurements: 1,     # Stage 1: Measure
    product_choices: 2,  # Stage 2: Product
    quote_review: 3,     # Stage 3: Sell
    contract: 4,         # Stage 3: Sell
    cancellation: 5,     # Stage 3: Sell
    payment: 6,          # Stage 3: Sell
    completed: 7
  }, default: :client_info

  scope :recent, -> { order(created_at: :desc) }
  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_client, ->(client_id) { where(client_id: client_id) }
  scope :templates, -> { where(is_template: true) }
  scope :live, -> { where(is_template: false) }
  scope :client_visible, -> { where.not(status: [ :draft ]) }

  # Bump the workflow_stage forward to the given stage, but never backward
  def bump_workflow_stage!(stage)
    target = self.class.workflow_stages[stage.to_sym]
    return unless target
    current = self.class.workflow_stages[workflow_stage.to_sym] || 0
    return if target <= current
    update!(workflow_stage: stage)
  end
end
