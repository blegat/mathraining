class AddNonameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :seename, :integer, :default => 1
  end
end
