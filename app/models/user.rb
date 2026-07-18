class User < ApplicationRecord
  # NOTE: :registerable intentionally removed.
  # Clients are invited by an admin (Brooke) — there is no public self-registration.
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  enum :role, { client: "client", tech: "tech", admin: "admin" }, default: "client"

  belongs_to :client, optional: true

  validates :role, presence: true

  scope :clients, -> { where(role: "client").order(:name) }
  scope :techs, -> { where(role: "tech").order(:name) }

  # Friendly display name: the name if set, otherwise the email's local part.
  def display_name
    name.presence || client&.name || email.split("@").first.titleize
  end

  def first_name
    display_name.split.first
  end
end
