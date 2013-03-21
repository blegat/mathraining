class AddOnlineToExercisesAndQcms < ActiveRecord::Migration
  def change
    add_column :exercises, :online, :boolean, default: false
    add_column :qcms, :online, :boolean, default: false
  end
end
