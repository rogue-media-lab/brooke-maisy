class CreateMoodBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :mood_boards do |t|
      t.references :design_presentation, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
