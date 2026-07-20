class AddClientReferenceToProjects < ActiveRecord::Migration[8.1]
  class User < ApplicationRecord
    self.table_name = "users"
  end

  class Client < ApplicationRecord
    self.table_name = "clients"
  end

  class Project < ApplicationRecord
    self.table_name = "projects"
  end

  def up
    add_reference :projects, :client, foreign_key: true, null: true

    # Backfill: for each project, create or find a Client from the linked User
    Project.find_each do |project|
      next unless project.user_id.present?
      user = User.find_by(id: project.user_id)
      next unless user

      client = Client.find_or_create_by!(name: user.name || user.email.split("@").first.titleize) do |c|
        c.email = user.email
      end
      project.update_column(:client_id, client.id)

      # Link the user to the client if not already linked
      user.update_column(:client_id, client.id) unless user.client_id.present?
    end

    # Enforce not null now that data is backfilled
    change_column_null :projects, :client_id, false
  end

  def down
    remove_reference :projects, :client
  end
end
