class DeleteToStudentsToActualities < ActiveRecord::Migration
  def change
    remove_column :actualities, :tostudents
  end
end
