class AddSubmissionToSolvedproblems < ActiveRecord::Migration
  def change
    add_column :solvedproblems, :submission_id, :integer
  end
end
