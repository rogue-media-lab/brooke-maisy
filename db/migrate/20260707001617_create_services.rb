class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.string :title, null: false
      t.text :description
      t.string :icon_name
      t.text :bullet_points
      t.integer :display_order, default: 0
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
