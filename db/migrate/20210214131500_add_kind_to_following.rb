class AddKindToFollowing < ActiveRecord::Migration[5.0]
  def change
    add_column :followings, :kind, :integer, :default => -1
    remove_index :followings, [:user_id]
    add_index :followings, [:user_id, :kind]
    add_index :followings, [:created_at]
  end
end
