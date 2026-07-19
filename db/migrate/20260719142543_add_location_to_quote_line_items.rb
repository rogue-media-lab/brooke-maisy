class AddLocationToQuoteLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :quote_line_items, :location, :string
  end
end
