class AddClientReferenceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :client, foreign_key: true, null: true
  end
end
