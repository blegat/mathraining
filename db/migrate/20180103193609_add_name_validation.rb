class AddNameValidation < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :valid_name, :boolean, :default => false
  end
end
