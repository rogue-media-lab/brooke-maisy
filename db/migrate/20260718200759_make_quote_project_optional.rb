class MakeQuoteProjectOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :quotes, :project_id, true
  end
end
