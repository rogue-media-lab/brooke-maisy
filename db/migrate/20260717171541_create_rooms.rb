class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name
      t.integer :position
      t.text :notes

      t.timestamps
    end
  end
end
