class AddGroups < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :group, :string, :default => ""
  end
end
