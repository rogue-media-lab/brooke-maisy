class CreateWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :windows do |t|
      t.references :room, null: false, foreign_key: true
      t.string :name
      t.decimal :width
      t.decimal :height
      t.string :mount_type
      t.decimal :depth
      t.text :notes
      t.integer :position

      t.timestamps
    end
  end
end
