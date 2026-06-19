class AddStatusToQuestionnaireSubmissions < ActiveRecord::Migration[8.1]
  def up
    add_column :questionnaire_submissions, :status, :string, default: "draft", null: false
    add_index :questionnaire_submissions, :status

    # Any row that existed before this migration was persisted under the old
    # code path, which only saved on a successful final submit. Treat them all
    # as completed submissions.
    execute <<~SQL.squish
      UPDATE questionnaire_submissions SET status = 'completed'
    SQL
  end

  def down
    remove_index :questionnaire_submissions, :status
    remove_column :questionnaire_submissions, :status
  end
end
