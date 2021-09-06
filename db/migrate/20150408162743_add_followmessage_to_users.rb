class AddFollowmessageToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :follow_message, :boolean, :default => false
  end
end
