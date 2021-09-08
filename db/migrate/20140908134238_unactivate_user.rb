class UnactivateUser < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :active, :boolean, :default => true
  end
end
