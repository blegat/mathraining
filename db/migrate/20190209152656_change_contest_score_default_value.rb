class ChangeContestScoreDefaultValue < ActiveRecord::Migration[5.0]
  def change
    change_column :contestsolutions, :score, :integer, :default => -1
  end
end
