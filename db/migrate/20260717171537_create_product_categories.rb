class CreateProductCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :product_categories do |t|
      t.string :name
      t.string :slug
      t.references :parent, null: true, foreign_key: { to_table: :product_categories }
      t.string :spec_template
      t.decimal :markup_override

      t.timestamps
    end
  end
end
