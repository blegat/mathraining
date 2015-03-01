class DeletePoints < ActiveRecord::Migration
  def change
    remove_index :points, :user_id
    drop_table :points
  end
end
