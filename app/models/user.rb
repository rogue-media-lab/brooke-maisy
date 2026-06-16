class User < ApplicationRecord
  # NOTE: :registerable intentionally removed.
  # Clients are invited by an admin (Brooke) — there is no public self-registration.
  # Other available modules: :confirmable, :lockable, :timeoutable, :trackable, :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  enum :role, { client: "client", admin: "admin" }, default: "client"

  validates :role, presence: true
end
