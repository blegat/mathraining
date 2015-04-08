class AddFollowmessageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :follow_message, :boolean, :default => false
  end
end
