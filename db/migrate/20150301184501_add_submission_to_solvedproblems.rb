class AddSubmissionToSolvedproblems < ActiveRecord::Migration[5.0]
  def change
    add_reference :solvedproblems, :submission
  end
end
