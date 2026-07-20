class AddOverrideCostToQuoteLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :quote_line_items, :override_cost, :decimal, precision: 8, scale: 2
  end
end
