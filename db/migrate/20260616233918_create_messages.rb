class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :service
      t.text :body
      t.boolean :read

      t.timestamps
    end
  end
end
