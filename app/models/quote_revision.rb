class QuoteRevision < ApplicationRecord
  belongs_to :quote

  validates :version_number, presence: true
  validates :snapshot, presence: true
end
