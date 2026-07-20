class AddComparisonGroupToQuoteLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :quote_line_items, :comparison_group, :string
  end
end
