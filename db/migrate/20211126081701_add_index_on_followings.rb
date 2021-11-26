class AddIndexOnFollowings < ActiveRecord::Migration[5.2]
  def change
    add_index :followings, [:user_id, :kind, :created_at]
    add_index :users, [:admin, :corrector]
  end
end
