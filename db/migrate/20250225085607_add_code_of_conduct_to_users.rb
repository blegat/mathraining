class AddCodeOfConductToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :accepted_code_of_conduct, :boolean, :default => false
  end
end
