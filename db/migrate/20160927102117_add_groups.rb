class AddGroups < ActiveRecord::Migration
  def change
  	add_column :users, :group, :string, :default => ""
  end
end
