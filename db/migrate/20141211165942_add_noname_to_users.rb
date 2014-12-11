class AddNonameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :seename, :integer, :default => 1
  end
end
