class CreatePromoCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :promo_codes do |t|
      t.string :code
      t.string :discount_type
      t.decimal :discount_value
      t.decimal :min_purchase
      t.date :expires_at
      t.integer :usage_limit
      t.integer :usage_count
      t.boolean :is_active

      t.timestamps
    end
  end
end
