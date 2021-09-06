class AddKeysToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :key, :string
    add_column :users, :email_confirm, :boolean, default: true
  end
end
