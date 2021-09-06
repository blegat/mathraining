class AddSkinToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :skin, :integer, :default => 0
  end
end
