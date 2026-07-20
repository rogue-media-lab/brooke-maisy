class CreateQuoteRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_revisions do |t|
      t.references :quote, null: false, foreign_key: true
      t.integer :version_number
      t.jsonb :snapshot

      t.timestamps
    end
  end
end
