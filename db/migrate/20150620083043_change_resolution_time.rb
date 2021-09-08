class ChangeResolutionTime < ActiveRecord::Migration[5.0]
  def change
    add_column :solvedproblems, :truetime, :datetime
  end
end
