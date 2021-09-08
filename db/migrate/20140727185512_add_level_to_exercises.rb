class AddLevelToExercises < ActiveRecord::Migration[5.0]
  def change
    add_column :exercises, :level, :integer, :default => 1
    add_column :qcms, :level, :integer, :default => 1
  end
end
