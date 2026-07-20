class CreateSwatches < ActiveRecord::Migration[8.1]
  def change
    create_table :swatches do |t|
      t.references :manufacturer, null: false, foreign_key: true
      t.string :name
      t.string :hex
      t.string :category
      t.string :color_range
      t.string :image_url
      t.boolean :is_new
      t.boolean :is_active

      t.timestamps
    end
  end
end
