class CreateProjectUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :project_updates do |t|
      t.references :project, null: false, foreign_key: true
      t.text :body, null: false
      t.boolean :visible_to_client, null: false, default: true

      t.timestamps
    end
  end
end
