class DeleteUselessColumnsFromSolvedquestions < ActiveRecord::Migration[7.0]
  def change
    remove_column :solvedquestions, :correct
    remove_column :solvedquestions, :guess
    drop_table :items_solvedquestions
  end
end
