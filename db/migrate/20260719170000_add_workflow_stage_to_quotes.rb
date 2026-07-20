class AddWorkflowStageToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :workflow_stage, :integer, null: false, default: 0
  end
end
