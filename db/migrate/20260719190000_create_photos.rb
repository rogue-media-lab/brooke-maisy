class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.references :room, foreign_key: true
      t.references :window, foreign_key: true
      t.references :quote, foreign_key: true
      t.string :label, null: false
      t.integer :kind, default: 0, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end
  end
end
