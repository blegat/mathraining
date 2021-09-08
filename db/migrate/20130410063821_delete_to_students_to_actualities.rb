class DeleteToStudentsToActualities < ActiveRecord::Migration[5.0]
  def change
    remove_column :actualities, :tostudents
  end
end
