class ChangeResolutionTime < ActiveRecord::Migration
  def change
    add_column :solvedproblems, :truetime, :datetime
  end
end
