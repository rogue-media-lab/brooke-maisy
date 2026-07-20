class CreateManufacturers < ActiveRecord::Migration[8.1]
  def change
    create_table :manufacturers do |t|
      t.string :name
      t.string :website
      t.string :trade_program_url
      t.decimal :trade_discount
      t.decimal :markup_override
      t.text :notes

      t.timestamps
    end
  end
end
