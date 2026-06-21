class CreateProductSelections < ActiveRecord::Migration[8.1]
  def change
    create_table :product_selections do |t|
      t.references :design_presentation, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :vendor
      t.decimal :price, precision: 10, scale: 2
      t.string :product_url
      t.string :room
      t.string :status, null: false, default: "proposed"
      t.text :client_notes
      t.integer :position, null: false, default: 0
      t.integer :quantity

      t.timestamps
    end
  end
end
