class AddKeysToUsers < ActiveRecord::Migration
  def change
    add_column :users, :key, :string
    add_column :users, :email_confirm, :boolean, default: true
  end
end
