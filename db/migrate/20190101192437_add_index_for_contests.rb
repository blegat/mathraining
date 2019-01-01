class AddIndexForContests < ActiveRecord::Migration[5.0]
  def change
     add_index :contests, :number
     add_index :contestsolutions, [:contestproblem_id, :user_id]
     add_index :subjects, :contest_id
  end
end
