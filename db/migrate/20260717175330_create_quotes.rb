class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.references :project, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :promo_code, null: true, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :version_number, null: false, default: 1
      t.decimal :subtotal
      t.string :quote_discount_type
      t.decimal :quote_discount_value
      t.string :quote_discount_reason
      t.decimal :adjusted_subtotal
      t.decimal :tax_rate
      t.decimal :tax_amount
      t.decimal :grand_total
      t.decimal :deposit_percentage
      t.decimal :deposit_amount
      t.decimal :balance_due
      t.date :valid_until
      t.text :notes
      t.datetime :sent_at
      t.datetime :approved_at

      t.timestamps
    end
  end
end
