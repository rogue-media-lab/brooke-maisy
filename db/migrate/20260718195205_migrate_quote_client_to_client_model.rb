class MigrateQuoteClientToClientModel < ActiveRecord::Migration[8.1]
  class User < ApplicationRecord
    self.table_name = "users"
  end

  class Client < ApplicationRecord
    self.table_name = "clients"
  end

  class Quote < ApplicationRecord
    self.table_name = "quotes"
  end

  def up
    # Drop the FK pointing to users FIRST, so we can repoint client_id
    remove_foreign_key :quotes, :users, column: :client_id rescue nil

    # Now backfill: remap quotes.client_id from User IDs to Client IDs
    Quote.find_each do |quote|
      next unless quote.client_id.present?
      user = User.find_by(id: quote.client_id)
      next unless user

      # Find the client that was backfilled from this user (by email or name)
      client = Client.find_by(email: user.email) if user.email.present?
      client ||= Client.find_or_create_by!(name: user.name || user.email.split("@").first.titleize) do |c|
        c.email = user.email
      end

      quote.update_column(:client_id, client.id)
    end

    # Add new FK pointing to clients
    add_foreign_key :quotes, :clients, column: :client_id
  end

  def down
    remove_foreign_key :quotes, :clients, column: :client_id
    add_foreign_key :quotes, :users, column: :client_id
  end
end
