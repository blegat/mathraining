class AddProblemIdToSubject < ActiveRecord::Migration[5.0]
  def change
    add_column :subjects, :problem_id, :integer
    add_index :subjects, :problem_id
    add_index :subjects, :question_id
  end
end
