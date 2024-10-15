class CreateGlobalStatistics < ActiveRecord::Migration[7.1]
  def change
    create_table :globalstatistics do |t|
      t.integer :nb_ranked_users, default: 0
      t.integer :nb_solvedproblems, default: 0
      t.integer :nb_solvedquestions, default: 0
      t.integer :nb_points, default: 0
    end
  end
end
