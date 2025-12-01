class AddWhitelistedToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :whitelisted, :boolean, :default => false
  end
end
