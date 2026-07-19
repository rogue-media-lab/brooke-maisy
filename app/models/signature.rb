class Signature < ApplicationRecord
  belongs_to :quote
  belongs_to :signable, polymorphic: true, optional: true

  has_one_attached :signature_image

  enum :signer, {
    client: 0,
    designer: 1
  }, default: :client

  enum :document_type, {
    agreement: 0,
    work_order: 1,
    change_order: 2,
    completion_signoff: 3,
    cancellation: 4
  }, default: :agreement

  validates :signed_at, presence: true
  validates :signed_name, presence: true

  scope :ordered, -> { order(:signed_at) }
end
