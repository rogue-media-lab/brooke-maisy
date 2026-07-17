class CreatePurchaseOrderLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_order_line_items do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.references :quote_line_item, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :unit_cost
      t.decimal :total_cost
      t.string :manufacturer_sku
      t.integer :status

      t.timestamps
    end
  end
end
