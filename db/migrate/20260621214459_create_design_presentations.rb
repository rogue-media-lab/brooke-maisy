class CreateDesignPresentations < ActiveRecord::Migration[8.1]
  def change
    create_table :design_presentations do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :design_presentations, [ :project_id, :status ]
  end
end
