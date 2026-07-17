class CreateProductSwatches < ActiveRecord::Migration[8.1]
  def change
    create_table :product_swatches do |t|
      t.references :product, null: false, foreign_key: true
      t.references :swatch, null: false, foreign_key: true

      t.timestamps
    end
  end
end
