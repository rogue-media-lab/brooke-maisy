class CreateQuestionnaireSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :questionnaire_submissions do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :preferred_contact
      t.jsonb :answers
      t.boolean :read, default: false, null: false

      t.timestamps
    end

    add_index :questionnaire_submissions, :created_at
    add_index :questionnaire_submissions, :email
  end
end
