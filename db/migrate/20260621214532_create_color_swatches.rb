class CreateColorSwatches < ActiveRecord::Migration[8.1]
  def change
    create_table :color_swatches do |t|
      t.references :design_presentation, null: false, foreign_key: true
      t.string :name, null: false
      t.string :hex_code, null: false
      t.string :brand
      t.string :finish
      t.string :room
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
