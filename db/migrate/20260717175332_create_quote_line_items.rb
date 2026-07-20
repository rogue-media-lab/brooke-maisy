class CreateQuoteLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_line_items do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :product, null: true, foreign_key: true
      t.references :window, null: true, foreign_key: true
      t.references :swatch, null: true, foreign_key: true
      t.string :description
      t.decimal :width
      t.decimal :height
      t.integer :quantity, null: false, default: 1
      t.jsonb :selected_options
      t.decimal :unit_cost
      t.decimal :unit_price
      t.string :discount_type
      t.decimal :discount_value
      t.string :discount_reason
      t.decimal :line_total
      t.integer :status, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.text :notes

      t.timestamps
    end
  end
end
