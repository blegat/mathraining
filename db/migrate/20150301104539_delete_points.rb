class DeletePoints < ActiveRecord::Migration[5.0]
  def change
    remove_index :points, :user_id
    drop_table :points
  end
end
