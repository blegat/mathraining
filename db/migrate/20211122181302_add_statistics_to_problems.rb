class AddStatisticsToProblems < ActiveRecord::Migration[5.2]
  def change
    add_column :problems, :nb_solved, :integer, :default => 0
    add_column :problems, :first_solved, :datetime
    add_column :problems, :last_solved, :datetime
  end
end
