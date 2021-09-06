class AddSubmissionToSolvedproblems < ActiveRecord::Migration[5.0]
  def change
    add_column :solvedproblems, :submission_id, :integer
  end
end
