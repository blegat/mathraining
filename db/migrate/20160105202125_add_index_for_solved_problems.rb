class AddIndexForSolvedProblems < ActiveRecord::Migration[5.0]
  def change
    add_index :solvedproblems, :truetime, order: "DESC"
    remove_index :solvedproblems, [:user_id, :resolutiontime]
    add_index :solvedproblems, [:user_id, :truetime], order: "DESC"
  end
end
