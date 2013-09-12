class AddSkinToUsers < ActiveRecord::Migration
  def change
    add_column :users, :skin, :integer, :default => 0
  end
end
