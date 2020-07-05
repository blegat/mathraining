class ModifyIndexForSolvedquestion < ActiveRecord::Migration[5.0]
  def change
    add_index :solvedquestions, [:question_id, :correct]
  end
end
