class AddCanChangeNameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :can_change_name, :boolean, :default => true
  end
end
