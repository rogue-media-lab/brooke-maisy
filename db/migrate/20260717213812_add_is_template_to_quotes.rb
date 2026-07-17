class AddIsTemplateToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :is_template, :boolean
  end
end
