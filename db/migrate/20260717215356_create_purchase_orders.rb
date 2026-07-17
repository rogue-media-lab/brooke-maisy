class CreatePurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_orders do |t|
      t.references :manufacturer, null: false, foreign_key: true
      t.references :quote, null: false, foreign_key: true
      t.integer :status
      t.date :order_date
      t.date :expected_delivery
      t.date :actual_delivery
      t.text :notes

      t.timestamps
    end
  end
end
