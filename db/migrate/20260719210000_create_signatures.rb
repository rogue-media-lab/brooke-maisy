class CreateSignatures < ActiveRecord::Migration[8.1]
  def change
    create_table :signatures do |t|
      t.references :quote, foreign_key: true, null: false
      t.references :signable, polymorphic: true
      t.integer :signer, null: false, default: 0
      t.integer :document_type, null: false, default: 0
      t.datetime :signed_at, null: false
      t.string :signed_name, null: false
      t.string :signature_ip
      t.string :signature_data
      t.timestamps
    end

    add_index :signatures, [ :signable_type, :signable_id ]
    add_index :signatures, [ :quote_id, :document_type ]
  end
end
