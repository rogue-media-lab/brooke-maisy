class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :address
      t.string :phone
      t.string :email
      t.text :notes

      t.timestamps
    end

    add_index :clients, :email
    add_index :clients, :name
  end
end
