class AddOnlineToExercisesAndQcms < ActiveRecord::Migration[5.0]
  def change
    add_column :exercises, :online, :boolean, default: false
    add_column :qcms, :online, :boolean, default: false
  end
end
