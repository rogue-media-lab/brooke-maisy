class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :manufacturer, null: false, foreign_key: true
      t.references :product_category, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :product_url
      t.string :unit
      t.jsonb :specs
      t.jsonb :pricing
      t.jsonb :images
      t.jsonb :videos
      t.jsonb :documents
      t.integer :lead_time_days
      t.boolean :is_active
      t.integer :tier
      t.text :notes

      t.timestamps
    end
  end
end
