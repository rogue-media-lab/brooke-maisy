class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :quote, foreign_key: true, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :method, default: 0, null: false
      t.integer :kind, default: 0, null: false
      t.datetime :paid_at, null: false
      t.string :reference
      t.text :notes
      t.timestamps
    end
  end
end
