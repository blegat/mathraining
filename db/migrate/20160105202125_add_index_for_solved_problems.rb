class AddIndexForSolvedProblems < ActiveRecord::Migration
  def change
    add_index :solvedproblems, :truetime, order: "DESC"
    remove_index :solvedproblems, [:user_id, :resolutiontime]
    add_index :solvedproblems, [:user_id, :truetime], order: "DESC"
  end
end
