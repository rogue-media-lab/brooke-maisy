class CreateTradePartners < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_partners do |t|
      t.string :name, null: false
      t.string :trade_type, null: false, default: "other"
      t.string :phone
      t.string :email
      t.string :website
      t.text :description
      t.integer :years_experience, default: 0
      t.decimal :rating, precision: 3, scale: 1, default: 0.0
      t.integer :jobs_referred, default: 0
      t.boolean :active, default: true
      t.integer :display_order, default: 0

      t.timestamps
    end
  end
end
