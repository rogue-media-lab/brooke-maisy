class AddUniqueIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :manufacturers, :name, unique: true
    add_index :product_categories, :slug, unique: true
    add_index :product_categories, [ :parent_id, :name ], unique: true, name: "index_product_categories_on_parent_and_name"
    add_index :promo_codes, :code, unique: true
    add_index :product_swatches, [ :product_id, :swatch_id ], unique: true, name: "index_product_swatches_on_product_and_swatch"
  end
end
