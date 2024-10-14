class ChangeStatsColumnsForQuestions < ActiveRecord::Migration[7.0]
  def change
    remove_column :questions, :nb_tries, :integer
    add_column :questions, :nb_correct, :integer, :default => 0
    add_column :questions, :nb_wrong, :integer, :default => 0
  end
end
