class AddPasswordStrengthToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :password_strength, :integer, :default => 0
  end
end
