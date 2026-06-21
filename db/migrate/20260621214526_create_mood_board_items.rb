class CreateMoodBoardItems < ActiveRecord::Migration[8.1]
  def change
    create_table :mood_board_items do |t|
      t.references :mood_board, null: false, foreign_key: true
      t.string :caption
      t.string :category
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
